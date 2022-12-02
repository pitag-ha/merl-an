open! Import

module Logs = struct
  type t = Error of string | Warning of string | Log of string
  [@@deriving to_yojson]

  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))

  let file = Fpath.v "logs.json"
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

  let file = Fpath.v "performance.json"
end

module Query_response = struct
  type t = { sample_id : int; merlin_reply : Merlin.Response.t option }
  [@@deriving to_yojson]

  (* FIXME: print each of the sample repeats in a separate json field *)
  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))

  let file = Fpath.v "merlin_reponses.json"
end

module Command = struct
  type t = { sample_id : int; cmd : Merlin.Cmd.t } [@@deriving to_yojson]

  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))

  let file = Fpath.v "commands.json"
end

module Metadata = struct
  (* TODO: add more metadata, such as:
     - the size of the AST per file
  *)
  type t = {
    merlin : Merlin.t;
    source_code_commit_sha : string option;
    date : string;
    total_time : float;
    query_time : float;
  }
  [@@deriving to_yojson]

  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))

  let file = Fpath.v "metadata.json"

  let get_commit_sha ~proj_dir =
    let cmd = "git rev-parse HEAD" in
    try
      let cwd = Unix.getcwd () in
      Unix.chdir proj_dir;
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

module type Table = sig
  (* FIXME *)
  (* type t *)

  (* val pp : Format.formatter -> t -> unit *)
  val file : Fpath.t
end

module Tables = struct
  type t = {
    mutable performances : Performance.t list;
    mutable query_responses : Query_response.t list;
    mutable commands : Command.t list;
    mutable metadata : Metadata.t list;
    mutable logs : Logs.t list;
  }
  [@@deriving fields]

  (* FIXME *)
  let table_of_string = function
    | "performances" -> (module Performance : Table)
    | "query_responses" -> (module Query_response : Table)
    | "commands" -> (module Command : Table)
    | "metadata" -> (module Metadata : Table)
    | "logs" -> (module Logs : Table)
    | _ ->
        Format.eprintf
          "Probably, there's a typo or an exhausitveness problem somewhere in \
           the Data module.";
        exit 10

  let files =
    List.fold_left
      (fun acc field_name ->
        let (module T) = table_of_string field_name in
        T.file :: acc)
      [] Fields.names

  let add_data ?perf ?resp ?cmd ?metadata ?log tables =
    let add_to_table table_field = function
      | None -> ()
      | Some data ->
          let field_setter = Option.get (Fieldslib.Field.setter table_field) in
          field_setter tables (data :: Fieldslib.Field.get table_field tables)
    in
    Fields.iter
      ~performances:(fun p -> add_to_table p perf)
      ~query_responses:(fun qr -> add_to_table qr resp)
      ~commands:(fun c -> add_to_table c cmd)
      ~metadata:(fun md -> add_to_table md metadata)
      ~logs:(fun e -> add_to_table e log)

  let write_json_list ~formatter ~filename table =
    let oc = open_out filename in
    Fun.protect
      ~finally:(fun () -> close_out_noerr oc)
      (fun () ->
        let ppf = Format.formatter_of_out_channel oc in
        Format.pp_print_list ~pp_sep:Format.pp_print_newline formatter ppf table)

  (* FIXME *)
  (* let dump ~dump_dir tables =
     let get_file_path file = Fpath.(to_string @@ append dump_dir (v file)) in
     let dump_table field =
       let table = Fieldslib.Field.get field tables in
       let (module Table) = table_of_string @@ Fieldslib.Field.name field in
       write_json_list ~formatter:Table.pp ~filename:Table.file table
       (*let oc = open_out Table.file in
         Fun.protect
          ~finally:(fun () -> close_out_noerr oc)
          (fun () ->
            let ppf = Format.formatter_of_out_channel oc in
            Format.pp_print_list ~pp_sep:Format.pp_print_newline Table.pp ppf
              table) *)
     in
     let f formatter file data_piece =
       let data_piece = Fieldslib.Field.get data_piece tables in
       let filename = get_file_path file in
       write_json_list ~formatter ~filename data_piece
     in
     Fields.iter
       ~performances:(fun p -> f Performance.pp Performance.file p)
       ~query_responses:(fun qr -> f Query_response.pp Query_response.file qr)
       ~commands:(fun c -> f Command.pp Command.file c)
       ~metadata:(fun md -> f Metadata.pp Metadata.file md)
       logs:(fun e -> f Error.pp Error.file e)
  *)

  let dump ~dump_dir tables =
    let get_file_path file = Fpath.(to_string @@ append dump_dir file) in
    let f formatter file data_piece =
      let data_piece = Fieldslib.Field.get data_piece tables in
      let filename = get_file_path file in
      write_json_list ~formatter ~filename data_piece
    in
    Fields.iter
      ~performances:(fun p -> f Performance.pp Performance.file p)
      ~query_responses:(fun qr -> f Query_response.pp Query_response.file qr)
      ~commands:(fun c -> f Command.pp Command.file c)
      ~metadata:(fun md -> f Metadata.pp Metadata.file md)
      ~logs:(fun e -> f Logs.pp Logs.file e)
end

type t = { dump_dir : Fpath.t; content : Tables.t }

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
  List.exists
    (fun fn ->
      match open_out Fpath.(to_string @@ append data_path fn) with
      | exception _ -> true
      | oc ->
          close_out_noerr oc;
          false)
    Tables.files

let init dump_dir =
  create_dir_recursively dump_dir;
  create_files dump_dir Tables.files;
  if some_file_isnt_writable dump_dir then (
    Format.eprintf "It's not possible to write to the data files\n%!";
    exit 20)
  else
    {
      dump_dir;
      content =
        {
          performances = [];
          query_responses = [];
          commands = [];
          metadata = [];
          logs = [];
        };
    }

let update ?perf ?resp ?cmd ?log ?metadata { content; dump_dir = _ } =
  Tables.add_data ?perf ?resp ?cmd ?metadata ?log content

let dump { dump_dir; content } = Tables.dump ~dump_dir content
