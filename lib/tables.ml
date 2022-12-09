open! Import

module Logs = struct
  type t = Error of string | Warning of string | Log of string
  [@@deriving to_yojson]

  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))
end

module Performance = struct
  (* TODO: add more data, such as:
     - the maximum of functor depth inside a file
     - info about the dependency graph of a file
  *)
  type t = {
    sample_id : int;
    timings : int list;
    max_timing : int;
    file : File.t;
    query_type : Merlin.Query_type.t;
    loc : Location.t;
  }
  [@@deriving to_yojson]

  (* FIXME: print each of the sample repeats in a separate json field *)
  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))
end

module Query_response = struct
  type t = { sample_id : int; responses : Merlin.Response.t list }
  [@@deriving to_yojson]

  (* FIXME: print each of the sample repeats in a separate json field *)
  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))
end

module Command = struct
  type t = { sample_id : int; cmd : Merlin.Cmd.t } [@@deriving to_yojson]

  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))
end

module Metadata = struct
  (* TODO: add more metadata, such as:
     - the size of the AST per file
  *)
  type t = {
    merlin : Merlin.t;
    source_code_commit_sha : string option;
    date : string option;
    total_time : float option;
    query_time : float option;
  }
  [@@deriving to_yojson]

  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))

  let get_commit_sha ~proj_path =
    let cmd = "git rev-parse HEAD" in
    try
      let cwd = Unix.getcwd () in
      Unix.chdir @@ Fpath.to_string proj_path;
      let ic = Unix.open_process_in cmd in
      Unix.chdir cwd;
      match input_line ic with
      | sha -> Ok sha
      | exception exc ->
          let err =
            Logs.Warning
              (Format.sprintf
                 "Warning: something went wrong trying to get the commit sha \
                  of the source code project: %s"
                 (Printexc.to_string exc))
          in
          Error err
    with exc ->
      let err =
        Logs.Warning
          (Format.sprintf
             "Warning: something went wrong trying to get the commit sha of \
              the source code project: %s"
             (Printexc.to_string exc))
      in
      Error err

  let get_date () =
    let epoch = Unix.time () |> Ptime.of_float_s |> Option.get in
    let (year, month, day), _ = Ptime.to_date_time epoch in
    Printf.sprintf "%i/%i/%i" day month year
end

type t = {
  performances : Performance.t list ref option;
  query_responses : Query_response.t list ref option;
  commands : Command.t list ref option;
  metadata : Metadata.t list ref option;
  logs : Logs.t list ref option;
}
[@@deriving fields]

let field_to_file field =
  let field_name = Fieldslib.Field.name field in
  Fpath.(add_ext ".json" @@ v field_name)

let all_files tables =
  let foo field =
    Fieldslib.Field.get field tables
    |> Option.map (fun _ -> field_to_file field)
  in
  Fields.to_list ~performances:foo ~query_responses:foo ~commands:foo
    ~metadata:foo ~logs:foo
  |> List.filter_map Fun.id

let add_data ?perf ?resp ?cmd ?metadata ?log tables =
  let add_to_table new_entry table_field =
    let table_content = Fieldslib.Field.get table_field tables in
    match (table_content, new_entry) with
    | _, None -> ()
    | None, Some _new_entry -> (
        let log =
          Format.sprintf "Tried to write to a table that doesn't exist: %s"
            (Fieldslib.Field.name table_field)
        in
        match tables.logs with
        | Some logs -> logs := Logs.Warning log :: !logs
        | None -> Format.printf "%s\n%!" log)
    | Some current_content, Some entry ->
        current_content := entry :: !current_content
  in
  Fields.iter ~performances:(add_to_table perf)
    ~query_responses:(add_to_table resp) ~commands:(add_to_table cmd)
    ~metadata:(add_to_table metadata) ~logs:(add_to_table log)

let dump ~dump_dir tables =
  let write_json_lines ~formatter ~file_path table =
    let oc = open_out file_path in
    Fun.protect
      ~finally:(fun () -> close_out_noerr oc)
      (fun () ->
        let ppf = Format.formatter_of_out_channel oc in
        Format.pp_print_list ~pp_sep:Format.pp_print_newline formatter ppf table)
  in
  let dump_field formatter field =
    match Fieldslib.Field.get field tables with
    | None -> ()
    | Some table ->
        let file_name = field_to_file field in
        let file_path = Fpath.(to_string @@ append dump_dir file_name) in
        write_json_lines ~formatter ~file_path !table
  in
  Fields.iter
    ~performances:(dump_field Performance.pp)
    ~query_responses:(dump_field Query_response.pp)
    ~commands:(dump_field Command.pp) ~metadata:(dump_field Metadata.pp)
    ~logs:(dump_field Logs.pp)

let update_analysis_data ~id ~responses ~cmd ~file ~loc ~query_type tables =
  let max_timing, timings, responses =
    (* FIXME: add json struture to the two lists *)
    let rec loop ~max_timing ~responses ~timings = function
      | [] -> (max_timing, timings, responses)
      | resp :: rest ->
          let timing = Merlin.Response.get_timing resp in
          let timings = timing :: timings in
          let responses = resp :: responses in
          let max_timing = Int.max timing max_timing in
          loop ~max_timing ~timings ~responses rest
    in
    loop ~max_timing:Int.min_int ~responses:[] ~timings:[] responses
  in
  let perf =
    (* if pure then None
       else *)
    Some
      { Performance.timings; max_timing; file; query_type; sample_id = id; loc }
  in
  let resp =
    let responses =
      (* if pure then List.map Merlin.Response.crop_timing responses else *)
      responses
    in
    { Query_response.sample_id = id; responses }
  in
  let cmd = { Command.sample_id = id; cmd } in
  add_data ?perf ~resp ~cmd tables

let update_log ~log tables = add_data ~log tables

let update_metadata ~proj_path ~merlin ~query_time tables =
  let metadata =
    (* if pure then
         {
           Metadata.merlin;
           source_code_commit_sha = None;
           date = None;
           total_time = None;
           query_time = None;
         }
       else *)
    let total_time = Some (Sys.time ()) in
    let source_code_commit_sha =
      match Metadata.get_commit_sha ~proj_path with
      | Ok sha -> Some sha
      | Error log ->
          update_log ~log tables;
          None
    in
    let date = Some (Metadata.get_date ()) in
    { Metadata.merlin; source_code_commit_sha; date; total_time; query_time }
  in
  add_data ~metadata tables

let create_empty () =
  {
    performances = (* (if pure then None else  *)
                   Some (ref []) (* ) *);
    query_responses = Some (ref []);
    commands = Some (ref []);
    metadata = Some (ref []);
    logs = Some (ref []);
  }
