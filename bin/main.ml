open! Merl_an.Import
open Cmdliner

let bench (`Merlin merlin_path) (`Proj_dir proj_dir) (`Dir_name data_dir)
    (`Cold cold) (`Sample_size sample_size) (`Query_types query_types)
    (`Extensions extensions) (`Repeats repeats) =
  let merlin_frontend =
    if cold then Merl_an.Merlin.Single else Merl_an.Merlin.Server
  in
  let merlin_path = Fpath.v merlin_path in
  let merlin = Merl_an.Merlin.make merlin_path merlin_frontend in
  let proj_path = Fpath.v (Unix.realpath proj_dir) in
  let data_dir =
    match data_dir with
    | Some dir -> Fpath.v dir
    | None ->
        let proj_name = Fpath.basename proj_path in
        let ts = Int.to_string @@ Int.of_float @@ Unix.time () in
        Fpath.v ("data/" ^ proj_name ^ "+" ^ ts)
  in
  let data = Merl_an.Data.init data_dir in
  match Merl_an.File.get_files ~extensions proj_path with
  | Ok files ->
      (*TODO: add terminal logging when getting the files: log number of files that are going to be benchmarked and, at the end, log how many that are.*)
      let side_effectively_add_data (qt, id_counter) (file, query_type) =
        match
          Merl_an.Samples.generate ~sample_size ~id_counter file query_type
        with
        | None ->
            let log =
              Merl_an.Data.Logs.Warning
                (Format.sprintf "File %s couldn't be parsed and was ignored.\n"
                   (Yojson.Safe.to_string @@ Merl_an.File.to_yojson file))
            in
            Merl_an.Data.update_log ~log data;
            (qt, id_counter)
        | Some (samples, new_id_counter) ->
            ( Merl_an.Samples.analyze ~merlin ~query_time:qt ~repeats data
                samples,
              new_id_counter )
      in
      let query_time, _last_sample_id =
        List.fold_over_product ~l1:files ~l2:query_types ~init:(0., 0)
          side_effectively_add_data
      in
      Merl_an.Data.update_metadata ~proj_path ~merlin ~query_time data;
      Merl_an.Data.dump data;
      Merl_an.Merlin.stop_server merlin
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
       merlin queries are then run on those samples. The analysis results are \
       dumped into json-line files.";
  ]

let cmd =
  let term =
    Term.(
      const bench $ Args.merlin $ Args.proj_dir $ Args.dir_name $ Args.cold
      $ Args.sample_size $ Args.query_types $ Args.extensions
      $ Args.repeats_per_sample)
  in
  let info =
    let doc =
      "Create a new data set to analyze ocamlmerlin on a given project."
    in
    Cmd.info "new" ~doc ~man
  in
  Cmd.v info term

let () = exit (Cmd.eval cmd)
