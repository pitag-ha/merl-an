open! Import

type kind = Perf | Regr | Bench

module type Data_tables = sig
  type t

  val kind : kind
  val create_initial : Merlin.t list -> t

  val update_analysis_data :
    id:int ->
    responses:Merlin.Response.t list ->
    cmd:Merlin.Cmd.t ->
    file:File.t ->
    loc:Location.t ->
    merlin_id:int ->
    query_type:Merlin.Query_type.t ->
    t ->
    unit

  val persist_logs : log:Logs.t -> t -> unit
  val dump : dump_dir:Fpath.t -> t -> unit
  val all_files : unit -> Fpath.t list
  val wrap_up : t -> dump_dir:Fpath.t -> proj_paths:Fpath.t list -> unit
end

module Field = struct
  (* A custom augmentation of [Fieldslib.Field] for [Data_tables.t] *)

  include Fieldslib.Field

  let to_filename field =
    let field_name = Fieldslib.Field.name field in
    Fpath.(add_ext ".json" @@ v field_name)

  let dump pp dump_dir tables field =
    let write_json_lines ~pp ~ppf l =
      Format.pp_print_list ~pp_sep:Format.pp_print_newline pp ppf l
    in
    let table_content = Fieldslib.Field.get field tables in
    let file_name = to_filename field in
    let file_path = Fpath.(to_string @@ append dump_dir file_name) in
    let oc = open_out file_path in
    Fun.protect
      ~finally:(fun () -> close_out_noerr oc)
      (fun () ->
        let ppf = Format.formatter_of_out_channel oc in
        write_json_lines ~pp ~ppf table_content)
end

module P = struct
  type t = {
    sample_id : int;
    timings : int list;
    max_timing : int;
    file : File.t;
    merlin_id : int;
    query_type : Merlin.Query_type.t;
    loc : Location.t;
  }
  [@@deriving yojson_of]

  (* FIXME: print each of the sample repeats in a separate json field *)
  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (yojson_of_t data))
end

module Query_response = struct
  type t = {
    sample_id : int;
    responses : Merlin.Response.t list;
    merlin_id : int;
  }
  [@@deriving yojson_of]

  (* FIXME: print the sample repeats in a separate json field *)
  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (yojson_of_t data))
end

module Command = struct
  type t = { sample_id : int; cmd : Merlin.Cmd.t; merlin_id : int }
  [@@deriving yojson_of]

  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (yojson_of_t data))
end

module Benchmark_result = struct
  type t = {
    name : string;
    (* TODO: different values *)
    value : int;
    units : string;
    description : string;
    trend : string option;
  }
  [@@deriving yojson_of]
end

module Benchmark_summary = struct
  type t = { name : string; mutable results : Benchmark_result.t list }
  [@@deriving yojson_of]

  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (yojson_of_t data))
end

(* module Files = struct
     type kind = Ml | Mli
     type t = {
       file_id : string (* could be the hash of the content *)
       name : string option (* None, when using [--sanitize] *)
       len : int;
       functor_depth : int;
       num_first_class_modules : int;
       cmi_deps : t list; (* note: probably not a good idea to have t itself... *)
       cmt_deps : t list; (* note: probably not a good idea to have t itself... *)
       commit_sha : string option;
     }
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
   end *)

module Performance = struct
  (* TODO: add more data/restructure data, such as:
     - add a files "table" containing things like
        - the length of the file (size of AST)
        - in-file max functor depth
        - number of first-class modules shipped around in the file
        - number of cmi/cmt dependencies
        - commit sha of that file
     - have a finer-grained level than sample_id to allow dedicated fields for the repeats of one query
     - possibly: add a query_types "table":
        - all query types used in that `merl-an` run
        - the AST node type(s) corresponding to that query
        - the way the cache is being initialized for that query
        - the way the query is run
  *)
  type t = {
    mutable performances : P.t list;
    mutable query_responses : Query_response.t list;
    mutable commands : Command.t list;
    mutable logs : Logs.t list;
    merlins : Merlin.t list;
  }
  [@@deriving fields]

  let kind = Perf

  let dump ~dump_dir t =
    let d = dump_dir in
    let () =
      Fields.iter ~performances:(Field.dump P.pp d t)
        ~query_responses:(Field.dump Query_response.pp d t)
        ~commands:(Field.dump Command.pp d t)
        ~logs:(Field.dump Logs.pp d t) ~merlins:(Field.dump Merlin.pp d t)
    in
    ()

  let update_analysis_data ~id ~responses ~cmd ~file ~loc ~merlin_id ~query_type
      tables =
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
      {
        P.timings;
        max_timing;
        file;
        query_type;
        sample_id = id;
        loc;
        merlin_id;
      }
    in
    let resp =
      (* TODO: make a cli-argument out of this instead of doing this always *)
      let responses = List.map Merlin.Response.crop_value responses in
      { Query_response.sample_id = id; responses; merlin_id }
    in
    let cmd = { Command.sample_id = id; cmd; merlin_id } in
    tables.performances <- perf :: tables.performances;
    tables.query_responses <- resp :: tables.query_responses;
    tables.commands <- cmd :: tables.commands

  let persist_logs ~log tables = tables.logs <- log :: tables.logs

  let create_initial merlins =
    {
      performances = [];
      query_responses = [];
      commands = [];
      logs = [];
      merlins;
    }

  module Metadata = struct
    type t = {
      date : string option;
      proj : string list;
      total_time : float; (* query_time : float; *)
    }
    [@@deriving yojson_of]

    let file_name = Fpath.v "metadata.json"

    let pp ppf data =
      Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (yojson_of_t data))

    let get_date () =
      let epoch = Unix.time () |> Ptime.of_float_s |> Option.get in
      let (year, month, day), _ = Ptime.to_date_time epoch in
      Printf.sprintf "%i/%i/%i" day month year

    let produce_and_dump ~dump_dir ~proj_paths =
      let metadata =
        let total_time = Sys.time () in
        let date = Some (get_date ()) in
        {
          date;
          proj = List.map Fpath.to_string proj_paths;
          total_time;
          (* query_time; *)
        }
      in
      let file_path = Fpath.(to_string @@ append dump_dir file_name) in
      let oc = open_out file_path in
      Fun.protect
        ~finally:(fun () -> close_out_noerr oc)
        (fun () ->
          let ppf = Format.formatter_of_out_channel oc in
          Format.fprintf ppf "%a" pp metadata)
  end

  let wrap_up _t ~dump_dir ~proj_paths =
    (* TODO: check whether there's data left in memory and, if so, dump it *)
    Metadata.produce_and_dump ~dump_dir ~proj_paths

  let all_files () =
    let f = Field.to_filename in
    Metadata.file_name
    :: Fields.to_list ~performances:f ~query_responses:f ~commands:f ~logs:f
         ~merlins:f
end

module Regression = struct
  type t = {
    mutable query_responses : Query_response.t list;
    mutable commands : Command.t list;
    mutable logs : Logs.t list;
  }
  [@@deriving fields]

  let kind = Regr

  let dump ~dump_dir t =
    let d = dump_dir in
    Fields.iter
      ~query_responses:(Field.dump Query_response.pp d t)
      ~commands:(Field.dump Command.pp d t)
      ~logs:(Field.dump Logs.pp d t)

  let update_analysis_data ~id ~responses ~cmd ~file:_ ~loc:_ ~merlin_id
      ~query_type:_ tables =
    let resp =
      let responses = List.map Merlin.Response.crop_timing responses in
      { Query_response.sample_id = id; responses; merlin_id }
    in
    let cmd = { Command.sample_id = id; cmd; merlin_id } in
    tables.query_responses <- resp :: tables.query_responses;
    tables.commands <- cmd :: tables.commands

  let persist_logs ~log tables = tables.logs <- log :: tables.logs

  let create_initial _merlins =
    { query_responses = []; commands = []; logs = [] }

  let wrap_up _t ~dump_dir:_ ~proj_paths:_ =
    (* TODO: check whether there's data left in memory and, if so, dump it *)
    ()

  let all_files () =
    let f = Field.to_filename in
    Fields.to_list ~query_responses:f ~commands:f ~logs:f
end

module Benchmark = struct
  type t = {
    mutable bench : Benchmark_summary.t list; (* TODO: rewrite to single, not list *)
    mutable query_responses : Query_response.t list;
    mutable commands : Command.t list;
    mutable logs : Logs.t list;
    merlins : Merlin.t list;
  }
  [@@deriving fields]

  let kind = Bench

  let create_initial merlins =
    {
      bench = [ { name = "Merlin benchmark"; results = [] } ] ;
      query_responses = [];
      commands = [];
      logs = [];
      merlins;
    }

  let persist_logs ~log tables = tables.logs <- log :: tables.logs

  let all_files () =
    let f = Field.to_filename in
    Fields.to_list ~bench:f ~query_responses:f ~commands:f ~logs:f ~merlins:f
        let dump ~dump_dir t =
    let d = dump_dir in
    let () =
      Fields.iter
        ~bench:(Field.dump Benchmark_summary.pp d t)
        ~query_responses:(Field.dump Query_response.pp d t)
        ~commands:(Field.dump Command.pp d t)
        ~logs:(Field.dump Logs.pp d t)
        ~merlins:(Field.dump Merlin.pp d t)
    in
    ()

    let update_analysis_data ~id ~responses ~cmd ~file ~loc:(_loc : Import.location) ~merlin_id ~query_type
      tables =
    let max_timing, _timings, responses =
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
    let bench_res =
      {
        Benchmark_result.name = File.filename file;
        value = max_timing;
        units = "todo";
        description =Merlin.Query_type.to_string query_type;
        trend = None;
      }
    in
    let resp =
      (* TODO: make a cli-argument out of this instead of doing this always *)
      let responses = List.map Merlin.Response.crop_value responses in
      { Query_response.sample_id = id; responses; merlin_id }
    in
    let cmd = { Command.sample_id = id; cmd; merlin_id } in
    let res = List.hd tables.bench in (* TODO: hack *)
    res.results <- bench_res :: res.results ;
    tables.query_responses <- resp :: tables.query_responses;
    tables.commands <- cmd :: tables.commands

    let wrap_up _t ~dump_dir:_ ~proj_paths:_ =
    (* TODO: check whether there's data left in memory and, if so, dump it *)
    ()
end
