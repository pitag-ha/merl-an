open! Merl_an.Import
open Cmdliner

let analyze ~backend:(module Backend : Merl_an.Backend.T) (`Repeats repeats)
    (`Merlin merlin_path) (`Proj_dir proj_dir) (`Dir_name data_dir) (`Cold cold)
    (`Sample_size sample_size) (`Query_types query_types)
    (`Extensions extensions) =
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
  let module D = Merl_an.Data.Make (Backend) in
  let data = D.init data_dir in
  match Merl_an.File.get_files ~extensions proj_path with
  | Ok files ->
      (*TODO: add terminal logging when getting the files: log number of files that are going to be benchmarked and, at the end, log how many that are.*)
      let side_effectively_add_data (qt, id_counter) (file, query_type) =
        match
          Merl_an.Samples.generate ~sample_size ~id_counter file query_type
        with
        | None ->
            let log =
              Merl_an.Logs.Warning
                (Format.sprintf "File %s couldn't be parsed and was ignored.\n"
                   (Yojson.Safe.to_string @@ Merl_an.File.to_yojson file))
            in
            D.persist_logs ~log data;
            (qt, id_counter)
        | Some (samples, new_id_counter) ->
            let update = D.update data in
            let persist_logs log = D.persist_logs ~log data in
            ( Merl_an.Samples.analyze ~merlin ~query_time:qt ~repeats ~update
                ~persist_logs samples,
              new_id_counter )
      in
      let query_time, _last_sample_id =
        List.fold_over_product ~l1:files ~l2:query_types ~init:(0., 0)
          side_effectively_add_data
      in
      D.persist_metadata data ~proj_path ~merlin ~query_time;
      D.dump data;
      (* let updater =
           Merl_an.Backend.update_metadata ~proj_path ~merlin
             ~query_time
         in *)
      (* Merl_an.Data.update_tables ~updater data; *)
      (* METADATA FIX *)
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

let performance_term =
  Term.(
    const
      (analyze
         ~backend:(module Merl_an.Backend.With_performance : Merl_an.Backend.T))
    $ Args.repeats_per_sample $ Args.merlin $ Args.proj_dir $ Args.dir_name
    $ Args.cold $ Args.sample_size $ Args.query_types $ Args.extensions)

let performance =
  let info =
    let doc =
      "Create a new data set, including a performance overview, to analyze  \
       ocamlmerlin on a given project."
    in
    Cmd.info "performance" ~doc ~man
  in
  Cmd.v info performance_term

let pure =
  let pure_term =
    Term.(
      const
        (analyze
           ~backend:
             (module Merl_an.Backend.With_performance : Merl_an.Backend.T)
           (`Repeats 1))
      $ Args.merlin $ Args.proj_dir $ Args.dir_name $ Args.cold
      $ Args.sample_size $ Args.query_types $ Args.extensions)
  in
  let info =
    let doc =
      "Create a new pure data set to analyze ocamlmerlin on a given project.  \
       To produce pure data, the [timing] component of the merlin response is  \
       being cropped. This command is useful for end-to-end regression  \
       analyzis of the ocamlmerlin responses. "
    in
    Cmd.info "pure" ~doc ~man
  in
  Cmd.v info pure_term

let main =
  Cmd.group ~default:performance_term (Cmd.info "merl-an" ~man)
    [ performance; pure ]

let () = exit (Cmd.eval main)
