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
    | Some dir -> Fpath.v dir
    | None ->
        let proj_name = Fpath.basename proj_path in
        let ts = Int.to_string @@ Int.of_float @@ Unix.time () in
        Fpath.v ("data/" ^ proj_name ^ "+" ^ ts)
  in
  let data = Data.init data_dir in
  match File.get_files ~extensions proj_path with
  | Ok files ->
      (*TODO: add terminal logging when getting the files: log number of files that are going to be benchmarked and, at the end, log how many that are.*)
      let side_effectively_add_data (qt, id_counter) (file, query_type) =
        match Samples.generate ~sample_size ~id_counter file query_type with
        | None ->
            let log =
              Data.Logs.Warning
                (Format.sprintf "File %s couldn't be parsed and was ignored.\n"
                   (Yojson.Safe.to_string @@ File.to_yojson file))
            in
            Data.update ~log data;
            (qt, id_counter)
        | Some (samples, new_id_counter) ->
            ( Samples.add_analysis_to_data ~merlin ~query_time:qt
                ~repeats_per_sample data samples,
              new_id_counter )
      in
      let total_query_time, _last_sample_id =
        List.fold_over_product ~l1:files ~l2:query_types ~init:(0., 0)
          side_effectively_add_data
      in
      let metadata =
        let total_time = Sys.time () in
        let source_code_commit_sha =
          match Data.Metadata.get_commit_sha ~proj_dir with
          | Ok sha -> Some sha
          | Error log ->
              Data.update ~log data;
              None
        in
        let date = Data.Metadata.get_date () in
        {
          Data.Metadata.merlin;
          source_code_commit_sha;
          date;
          total_time;
          query_time = total_query_time;
        }
      in

      Data.update ~metadata data;
      Data.dump data;
      Merlin.stop_server merlin
  | Error (`Msg err) ->
      Printf.eprintf "%s" err;
      exit 50

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
