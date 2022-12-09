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

module Tables = struct
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
          Format.pp_print_list ~pp_sep:Format.pp_print_newline formatter ppf
            table)
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
end

type t = { pure : bool; dump_dir : Fpath.t; mutable content : Tables.t }

let create_dir_recursively data_path =
  let dir = Fpath.to_string data_path in
  if Sys.file_exists dir then (
    (* possible TODO: prompt would be nicer *)
    Format.printf
      "Your data directory %a already exists. So the data in there will be \
       overriden. Sure you want that?? If not, you should interrupt now.\n\
       %!"
      Fpath.pp data_path;
    Unix.sleep 60)
  else
    let _ =
      Fpath.segs data_path |> List.map Fpath.v
      |> List.fold_left
           (fun last_dir b ->
             let dir =
               match last_dir with
               | Some last_dir -> Fpath.(append last_dir b)
               | None -> b
             in
             let () =
               try Sys.mkdir (Fpath.to_string dir) 0o777 with _ -> ()
             in
             Format.printf "dir: %a\n%!" Fpath.pp dir;
             Some dir)
           None
    in
    ()

let create_files dir =
  List.iter (fun fn ->
      let path = Fpath.(to_string @@ append dir fn) in
      let descr = Unix.openfile path [ Unix.O_CREAT ] 0o777 in
      Unix.close descr)

let some_file_isnt_writable data_path =
  List.exists (fun fn ->
      match open_out Fpath.(to_string @@ append data_path fn) with
      | exception _ -> true
      | oc ->
          close_out_noerr oc;
          false)

let init ~pure dump_dir =
  create_dir_recursively dump_dir;
  let tables =
    {
      Tables.performances = (if pure then None else Some (ref []));
      query_responses = Some (ref []);
      commands = Some (ref []);
      metadata = Some (ref []);
      logs = Some (ref []);
    }
  in
  let data_files = Tables.all_files tables in
  create_files dump_dir data_files;
  if some_file_isnt_writable dump_dir data_files then (
    Format.eprintf "It's not possible to write to the data files\n%!";
    exit 20)
  else { pure; dump_dir; content = tables }

let update_analysis_data ~id ~responses ~cmd ~file ~loc ~query_type
    { content; pure; dump_dir = _ } =
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
    if pure then None
    else
      Some
        {
          Performance.timings;
          max_timing;
          file;
          query_type;
          sample_id = id;
          loc;
        }
  in
  let resp =
    let responses =
      if pure then List.map Merlin.Response.crop_timing responses else responses
    in
    { Query_response.sample_id = id; responses }
  in
  let cmd = { Command.sample_id = id; cmd } in
  Tables.add_data ?perf ~resp ~cmd content

let update_log ~log { content; pure = _; dump_dir = _ } =
  Tables.add_data ~log content

let update_metadata ~proj_path ~merlin ~query_time
    ({ content; pure; dump_dir = _ } as data) =
  let metadata =
    if pure then
      {
        Metadata.merlin;
        source_code_commit_sha = None;
        date = None;
        total_time = None;
        query_time = None;
      }
    else
      let total_time = Some (Sys.time ()) in
      let source_code_commit_sha =
        match Metadata.get_commit_sha ~proj_path with
        | Ok sha -> Some sha
        | Error log ->
            update_log ~log data;
            None
      in
      let date = Some (Metadata.get_date ()) in
      { Metadata.merlin; source_code_commit_sha; date; total_time; query_time }
  in
  Tables.add_data ~metadata content

let dump { dump_dir; content; pure = _ } = Tables.dump ~dump_dir content
