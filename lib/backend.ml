open! Import

(* new idea:
   -
   -   - separate out `Metadata` into its own module. different `Metadata` module for different backend (i.e. `pure`
    and `performance`)
   -   - here, define two modules: `Pure` and `Performance` of the module type
   -       sig
   -       type t
   -       val all_files : Fpath.t list
   -       val update_log : log -> t -> unit
   -       val update_analysis_data : id:int ->
   -           responses:Merlin.Response.t list ->
   -           cmd:Merlin.Cmd.t ->
   -           file:File.t -> loc:Warnings.loc -> query_type:Merlin.Query_type.t -> t -> unit
   -      val dump : dump_dir:Fpath.t -> t -> unit
   -      val create_empty : unit -> t
   -   - also separate out the file creation logic from Data to its own module
   -   - at the end of main, create `Metadata` and immediately dump it; `Metadata` can get its own design that way and doesn't need to have the same design as the one of the other tables
   -   - convert `Data` into a functor that takes a `Table` backend (`pure` or `performance`) as parameter
   -   - possibly, add more things to the `Data` module that are attached to the data, such as the `project_dir`
   -   - think about what exactly to do about `Metadata`!! for example, there could be two different functions
   -   `add_pure_metadata` and `add_detailed_metadata`. the `Data.t` value could have a `backend : `Pure | `Performance` value.
   -   then, in main, I could do something like `match backend data with | `Pure -> add_pure_metadata | `Performance -> add_detailed_metadata
   -*)

type kind = With_perf | Pure

let field_to_file field =
  let field_name = Fieldslib.Field.name field in
  Fpath.(add_ext ".json" @@ v field_name)

let dump_field formatter dump_dir tables field =
  let table = Fieldslib.Field.get field tables in
  let file_name = field_to_file field in
  let file_path = Fpath.(to_string @@ append dump_dir file_name) in
  Io.write_json_lines ~formatter ~file_path table

module type T = sig
  type t

  val kind : kind
  val create_empty : unit -> t

  val update_analysis_data :
    t ->
    id:int ->
    responses:Merlin.Response.t list ->
    cmd:Merlin.Cmd.t ->
    file:File.t ->
    loc:Warnings.loc ->
    query_type:Merlin.Query_type.t ->
    unit

  val persist_logs : log:Logs.t -> t -> unit
  val dump : dump_dir:Fpath.t -> t -> unit
  val all_files : unit -> Fpath.t list

  val persist_metadata :
    t -> proj_path:Fpath.t -> merlin:Merlin.t -> query_time:float -> unit
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
    total_time : float;
    query_time : float;
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

  (* let update_metadata ~proj_path ~merlin ~query_time tables =
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
     add_data ~metadata tables *)
end

module With_performance = struct
  type t = {
    mutable performances : Performance.t list;
    mutable query_responses : Query_response.t list;
    mutable commands : Command.t list;
    mutable metadata : Metadata.t list;
    mutable logs : Logs.t list;
  }
  [@@deriving fields]

  let kind = With_perf

  let all_files () =
    let f = field_to_file in
    Fields.to_list ~performances:f ~query_responses:f ~commands:f ~metadata:f
      ~logs:f

  let dump ~dump_dir t =
    let d = dump_dir in
    Fields.iter
      ~performances:(dump_field Performance.pp d t)
      ~query_responses:(dump_field Query_response.pp d t)
      ~commands:(dump_field Command.pp d t)
      ~metadata:(dump_field Metadata.pp d t)
      ~logs:(dump_field Logs.pp d t)

  let update_analysis_data tables ~id ~responses ~cmd ~file ~loc ~query_type =
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
    tables.performances <- perf :: tables.performances;
    tables.query_responses <- resp :: tables.query_responses;
    tables.commands <- cmd :: tables.commands

  let persist_logs ~log tables = tables.logs <- log :: tables.logs

  let create_empty () =
    {
      performances = (* (if pure then None else  *)
                     [] (* ) *);
      query_responses = [];
      commands = [];
      metadata = [];
      logs = [];
    }

  (* FIXME!! *)
  let persist_metadata tables ~proj_path ~merlin ~query_time =
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
      let total_time = Sys.time () in
      let source_code_commit_sha =
        match Metadata.get_commit_sha ~proj_path with
        | Ok sha -> Some sha
        | Error log ->
            persist_logs ~log tables;
            None
      in
      let date = Some (Metadata.get_date ()) in
      { Metadata.merlin; source_code_commit_sha; date; total_time; query_time }
    in
    tables.metadata <- metadata :: tables.metadata
end

(* FIXME *)
module Pure = With_performance
