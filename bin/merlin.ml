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

let untimed_query cmd =
  let ic = Unix.open_process_in cmd in
  match Yojson.Safe.from_channel ic with
  | json -> (
      match Unix.close_process_in ic with
      | Unix.WEXITED 0 -> json
      | Unix.WEXITED code ->
          failwith ("merlin exited with code " ^ string_of_int code)
      | _ -> failwith "merlin closed unexpectedly")
  | exception e ->
      print_endline "merlin server exception\n";
      ignore (Unix.close_process_in ic);
      raise e

let query ~query_time cmd =
  let start_time = Sys.time () in
  let repl = untimed_query cmd in
  (repl, query_time +. Sys.time () -. start_time)

let make path frontend =
  let cmd = Printf.sprintf "%s -version" (print path frontend) in
  let version = untimed_query cmd in
  { path; frontend; version }

module Query_type = struct
  type t = Locate | Case_analysis | Type_enclosing | Occurrences
  [@@deriving to_yojson]

  (* TODO: could make this more future-proof *)
  let all = [ Locate; Case_analysis; Type_enclosing; Occurrences ]

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
end

module Cmd = struct
  type t = string

  let make ~query_type ~file ~loc merlin =
    match query_type with
    | Query_type.Locate ->
        Format.asprintf
          " %a locate -look-for ml -position '%a' -index 0 -filename %a < %a" pp
          merlin
          (Location.print_edge Right)
          loc File.pp file File.pp file
    | Case_analysis ->
        Format.asprintf
          "%a case-analysis -start '%a' -end '%a' -filename %a < %a" pp merlin
          (Location.print_edge Left) loc
          (Location.print_edge Right)
          loc File.pp file File.pp file
    | Type_enclosing ->
        Format.asprintf "%a type-enclosing -position '%a' -filename %a < %a" pp
          merlin
          (Location.print_edge Right)
          loc File.pp file File.pp file
    | Occurrences ->
        Format.asprintf "%a occurrences -identifier-at '%a' -filename %a < %a"
          pp merlin
          (Location.print_edge Right)
          loc File.pp file File.pp file
end

let init_cache ~query_time ~query_type ~file ~loc merlin =
  match merlin.frontend with
  | Single -> query_time
  | Server ->
      let cmd = Cmd.make ~query_type ~file ~loc merlin in
      let _, query_time = query ~query_time cmd in
      query_time

let stop_server { path; frontend; _ } =
  match frontend with
  | Single -> ()
  | Server -> (
      let command = Fpath.to_string path ^ " server stop-server" in
      match Sys.command command with
      | 255 -> ()
      | code -> failwith ("merlin exited with code " ^ string_of_int code))
