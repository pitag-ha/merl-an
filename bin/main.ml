open! Import
open Cmdliner

let bench merlin_path proj_dir data_dir cold sample_size query_types extensions
    repeats_per_sample =
  let merlin_frontend = if cold then Merlin.Single else Merlin.Server in
  let merlin_path = Fpath.v merlin_path in
  let merlin = Merlin.make merlin_path merlin_frontend in
  let proj_path = Fpath.v (Unix.realpath proj_dir) in
  let data_dir =
    match data_dir with
    | Some dir -> dir
    | None ->
        let proj_name = Fpath.basename proj_path in
        let ts = Float.to_string @@ Unix.time () in
        "data/" ^ proj_name ^ "+" ^ ts
  in
  (* TODO: in Data module: add type [t], which contains the data_dir; if data_dir doesn't exist, it creates it. write function, to check if a value of [t] is writable. add to each submodule there the name of the data file. then, in [dump], replace [filename] by [t] value and append data file name to it.contents
      here: create value of that type, then check whether it's writable, before creating the benchmarks. *)
  match File.get_files ~extensions proj_path with
  | Ok files ->
      (*TODO: add logging when getting the files: log which files are going to be benchmarked and, at the end, log how many that are.*)
      let add_data ((timing_data, query_data, qt), id_counter) (file, query_type)
          =
        match Samples.generate ~sample_size ~id_counter file query_type with
        | None -> ((timing_data, query_data, qt), id_counter)
        (* TODO: add to error data: "Error: file %s couldn't be parsed and was ignored.\n" *)
        | Some (samples, new_id_counter) ->
            ( Samples.add_benchmarks ~merlin ~query_time:qt
                ~current_data:(timing_data, query_data) ~repeats_per_sample
                samples,
              new_id_counter )
      in
      let (timing_data, query_data, total_query_time), _last_sample_id =
        List.fold_over_product ~l1:files ~l2:query_types
          ~init:(([], [], 0.), 0)
          add_data
      in
      if not (Sys.file_exists data_dir) then
        (* FIXME: this isn't setting the permissions right *)
        Sys.mkdir data_dir (int_of_string "0x777");
      (* FIXME: remove the following 3 lines and instead do the TODO above. *)
      let oc = open_out (data_dir ^ "/timing.json") in
      close_out_noerr oc;
      Data.dump ~formatter:Data.Timing.print
        ~filename:(data_dir ^ "/timing.json")
        timing_data;
      Data.dump ~formatter:Data.Query_info.print
        ~filename:(data_dir ^ "/query_info.json")
        query_data;
      let total_time = Sys.time () in
      let metadata =
        { Data.Metadata.total_time; query_time = total_query_time; merlin }
      in
      Data.dump ~formatter:Data.Metadata.print
        ~filename:(data_dir ^ "/metadata.json")
        [ metadata ];
      Merlin.stop_server merlin
  | Error (`Msg err) -> Printf.eprintf "%s" err

let man =
  [
    `S Manpage.s_description;
    `P
      "This creates analysis data for ocamlmerlin on a given project as \
       follows. For each ml and/or mli file in the project, a random (but \
       deterministic) sample set of locations is generated. The different \
       merlin queries are then run on those samples. The benchmark results are \
       dumped into a performance.json file; the merlin responses into a \
       query_info.json file.";
  ]

let merlin =
  let doc = "Path to the ocamlmerlin executable. Defaults to [ocamlmerlin]." in
  Arg.(value & opt string "ocamlmerlin" & info [ "merlin"; "m" ] ~doc)

let proj_dir =
  let doc =
    "Directory path of the project, on which you want merlin to be \
     benchmarked. Defaults to [.]"
  in
  Arg.(value & opt string "." & info [ "project"; "p" ] ~doc)

let dir_name =
  let doc =
    "Directory, in which the data is going to be stored. If the directory \
     doesn't exist, it's created. If the same directory was already used in \
     the past, the data will be overridden. Defaults to \
     [data/<project>+<unix_timestamp>/]."
  in
  Arg.(value & opt (some string) None & info [ "data" ] ~doc)

let cold =
  let doc =
    "By default, the merlin frontend [server] is being used and its cache is \
     being initialized before collecting the data. That simulates a user doing \
     lots of merlin queries without modifying the source code in between. If \
     you want to simluate a user, who modifies the source code each time \
     between two merlin queries, use this flag: it switches the frontend to \
     [single]."
  in
  Arg.(value & flag & info [ "cold" ] ~doc)

let sample_size =
  let doc = "Number of samples per file. Defaults to 30." in
  Arg.(value & opt int 30 & info [ "sample-size"; "s" ] ~doc)

let query_types =
  let doc =
    let all_query_types =
      List.map Merlin.Query_type.to_string Merlin.Query_type.all
      |> String.concat ", "
    in
    "List of merlin commands you want to be analyzed. Options are "
    ^ all_query_types ^ ". Defaults to all of them."
  in
  let e =
    Arg.enum
    @@ List.map
         (fun qt -> (Merlin.Query_type.to_string qt, qt))
         Merlin.Query_type.all
  in
  Arg.(
    value & opt (list e) Merlin.Query_type.all & info [ "queries"; "q" ] ~doc)

let extensions =
  let doc =
    "List of file extensions you want this tool to analyze data for. Options \
     are [ml] and [mli]. Defaults to both."
  in
  let e = Arg.enum [ ("ml", "ml"); ("mli", "mli") ] in
  Arg.(value & opt (list e) [ "ml"; "mli" ] & info [ "extensions"; "e" ] ~doc)

let repeats_per_sample =
  let doc =
    "Number of times you want the same query to be run on the same sample. The \
     higher that number, the better to analyze variance. Defaults to 10."
  in
  Arg.(value & opt int 10 & info [ "repeats"; "r" ] ~doc)

let cmd =
  let term =
    Term.(
      const bench $ merlin $ proj_dir $ dir_name $ cold $ sample_size
      $ query_types $ extensions $ repeats_per_sample)
  in
  let info =
    let doc =
      "Create a new data set to analyze ocamlmerlin on a given project."
    in
    Cmd.info "new" ~doc ~man
  in
  Cmd.v info term

let () = exit (Cmd.eval cmd)
