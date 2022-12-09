open! Import

type frontend = Server | Single [@@deriving yojson]

module Path = struct
  type t = Fpath.t

  let to_yojson path = `String (Fpath.to_string path)
end

type t = { path : Path.t; frontend : frontend; version : Yojson.Safe.t }
[@@deriving to_yojson]

let print path = function
  | Server -> Format.sprintf "%s server" (Fpath.to_string path)
  | Single -> Format.sprintf "%s single" (Fpath.to_string path)

let pp ppf { path; frontend; _ } = Format.fprintf ppf "%s" (print path frontend)

let untimed_query_generic ~f cmd =
  let ic = Unix.open_process_in cmd in
  match f ic with
  | res -> (
      match Unix.close_process_in ic with
      | Unix.WEXITED 0 -> res
      | Unix.WEXITED code ->
          Format.eprintf "merlin exited with code %s\n%!" (string_of_int code);
          exit 1
      | _ ->
          Format.eprintf "merlin closed unexpectedly\n%!";
          exit 2)
  | exception e ->
      ignore (Unix.close_process_in ic);
      let s =
        Format.sprintf "exception while running [%s]: %s\n%!" cmd
          (Printexc.to_string e)
      in
      failwith s

let untimed_query_json cmd =
  let f = Yojson.Safe.from_channel in
  untimed_query_generic ~f cmd

let untimed_query_str cmd =
  let f = input_line in
  untimed_query_generic ~f cmd

let make path frontend =
  let cmd = Printf.sprintf "%s -version" (print path frontend) in
  let version = `String (untimed_query_str cmd) in
  { path; frontend; version }

module Query_type = struct
  (* TODO: also add [complete-prefix] command. that's a little more complex than the other commands since, aside location and file name, it also requires a prefix of the identifier as input. *)
  type t = Locate | Case_analysis | Type_enclosing | Occurrences
  [@@deriving to_yojson, enumerate]

  let to_string = function
    | Locate -> "locate"
    | Case_analysis -> "case-analysis"
    | Type_enclosing -> "type-enclosing"
    | Occurrences -> "occurrences"

  type node = Longident | Expression | Var_pattern [@@deriving yojson]

  let has_target qt target =
    let target_nodes =
      match qt with
      | Locate -> [ Longident ]
      | Case_analysis -> [ Expression; Var_pattern ]
      | Type_enclosing -> [ Expression ]
      | Occurrences -> [ Longident ]
    in
    List.mem target target_nodes
end

module Response = struct
  type t = Yojson.Safe.t

  let to_yojson x = x

  let get_timing = function
    | `Assoc answer -> (
        match List.assoc "timing" answer with
        | `Assoc timing -> (
            match List.assoc "clock" timing with
            | `Int time -> time
            | _ -> failwith "merlin gave bad output")
        | _ -> failwith "merlin gave bad output")
    | _ -> failwith "merlin gave bad output"

  let crop_timing = function
    | `Assoc answer -> `Assoc (List.remove_assoc "timing" answer)
    | _ ->
        failwith
          "Error while cropping merlin response: reponse should have a key \
           called timing."
end

module Cmd = struct
  type t = string

  let to_yojson cmd = `String cmd

  let make ~query_type ~file ~loc merlin =
    match query_type with
    | Query_type.Locate ->
        Format.asprintf
          " %a %s -look-for ml -position '%a' -index 0 -filename %a < %a" pp
          merlin
          (Query_type.to_string query_type)
          (Location.print_edge Right)
          loc File.pp file File.pp file
    | Case_analysis ->
        Format.asprintf "%a %s -start '%a' -end '%a' -filename %a < %a" pp
          merlin
          (Query_type.to_string query_type)
          (Location.print_edge Left) loc
          (Location.print_edge Right)
          loc File.pp file File.pp file
    | Type_enclosing ->
        Format.asprintf "%a %s -position '%a' -filename %a < %a" pp merlin
          (Query_type.to_string query_type)
          (Location.print_edge Right)
          loc File.pp file File.pp file
    | Occurrences ->
        Format.asprintf "%a %s -identifier-at '%a' -filename %a < %a" pp merlin
          (Query_type.to_string query_type)
          (Location.print_edge Right)
          loc File.pp file File.pp file

  let some_global_cmd file merlin =
    Format.asprintf "%a errors -filename %a < %a" pp merlin File.pp file File.pp
      file

  let run_once ~query_time cmd =
    let start_time = Sys.time () in
    let repl = untimed_query_json cmd in
    (repl, query_time +. Sys.time () -. start_time)

  let run ~query_time ~repeats cmd =
    let rec loop ~query_time responses = function
      | 0 -> (responses, query_time)
      | n ->
          let new_resp, query_time = run_once ~query_time cmd in
          loop ~query_time (new_resp :: responses) (n - 1)
    in
    loop ~query_time [] repeats
end

let init_cache ~query_time file merlin =
  match merlin.frontend with
  | Single -> Ok query_time
  | Server -> (
      let cmd = Cmd.some_global_cmd file merlin in
      try
        let _, query_time = Cmd.run_once ~query_time cmd in
        Ok query_time
      with exc -> Error (Logs.Error (Printexc.to_string exc)))

let stop_server { path; frontend; _ } =
  match frontend with
  | Single -> ()
  | Server -> (
      let command = Fpath.to_string path ^ " server stop-server" in
      match Sys.command command with
      | 255 -> ()
      | code -> failwith ("merlin exited with code " ^ string_of_int code))
