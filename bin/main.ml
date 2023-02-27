open! Merl_an.Import
open Cmdliner

let analyze ~backend:(module Backend : Merl_an.Backend.Data_tables)
    (`Repeats repeats) (`Cache cache_workflows) (`Merlin merlin_path)
    (`Proj_dirs proj_dirs) (`Dir_name data_dir) (`Sample_size sample_size)
    (`Query_types query_types) (`Extensions extensions) =
  let merlin_path = Fpath.v merlin_path in
  let merlins =
    List.mapi (fun i -> Merl_an.Merlin.make i merlin_path) cache_workflows
  in
  let proj_path dir = Fpath.v @@ Unix.realpath @@ dir in
  let data_dir =
    match data_dir with
    | Some dir -> Fpath.v dir
    | None ->
        let proj_name =
          match proj_dirs with
          | [] ->
              Printf.eprintf "Expected at least one file or project to analyze";
              exit 50
          | [ proj_dir ] -> Fpath.basename @@ proj_path proj_dir
          | proj_dir :: l ->
              let num = List.length l in
              let base = Fpath.basename @@ proj_path proj_dir in
              Format.sprintf "%s+%iothers" base num
        in
        let ts = Int.to_string @@ Int.of_float @@ Unix.time () in
        Fpath.v ("data/" ^ proj_name ^ "+" ^ ts)
  in
  let module D = Merl_an.Data.Make (Backend) in
  let data = D.init merlins data_dir in
  let proj_paths = List.map proj_path proj_dirs in
  match Merl_an.File.get_files ~extensions proj_paths with
  | Ok files -> (
      (*TODO: add terminal logging when getting the files: log number of files that are going to be benchmarked and, at the end, log how many that are.*)
      let side_effectively_add_data (qt, id_counter) (file, query_type) =
        match
          Merl_an.Samples.generate ~sample_size ~id_counter file query_type
        with
        | None ->
            let log =
              Merl_an.Logs.Warning
                (Format.sprintf "File %s couldn't be parsed and was ignored.\n"
                   (Yojson.Safe.to_string @@ Merl_an.File.yojson_of_t file))
            in
            D.persist_logs ~log data;
            (qt, id_counter)
        | Some (samples, new_id_counter) -> (
            let update = D.update data in
            match
              Merl_an.Samples.analyze ~merlins ~query_time:qt ~repeats ~update
                samples
            with
            | Ok new_query_time -> (new_query_time, new_id_counter)
            | Error log ->
                D.persist_logs ~log data;
                (qt, new_id_counter))
      in
      let query_time, _last_sample_id =
        List.fold_over_product ~l1:files ~l2:query_types ~init:(0., 0)
          side_effectively_add_data
      in
      D.dump data;
      D.wrap_up data ~proj_paths ~query_time;
      match List.find_opt Merl_an.Merlin.is_server merlins with
      | Some merlin -> Merl_an.Merlin.stop_server merlin
      | None -> ())
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
  let backend =
    (module Merl_an.Backend.Performance : Merl_an.Backend.Data_tables)
  in
  Term.(
    const (analyze ~backend)
    $ Args.repeats_per_sample $ Args.cache_workflows $ Args.merlin
    $ Args.proj_dirs $ Args.dir_name $ Args.sample_size $ Args.query_types
    $ Args.extensions)

let performance =
  let info =
    let doc =
      "Create a new data set, including a performance overview, to analyze  \
       ocamlmerlin on a given project."
    in
    Cmd.info "performance" ~doc ~man
  in
  Cmd.v info performance_term

let regression =
  let backend =
    (module Merl_an.Backend.Regression : Merl_an.Backend.Data_tables)
  in
  let regression_term =
    Term.(
      const
        (analyze ~backend (`Repeats 1) (`Cache [ Merl_an.Merlin.Cache.Warm ]))
      $ Args.merlin $ Args.proj_dirs $ Args.dir_name $ Args.sample_size
      $ Args.query_types $ Args.extensions)
  in
  let info =
    let doc =
      "Create a new pure data set to analyze ocamlmerlin on a given project. \
       The data is pure in the sense that if you run the command twice with \
       the same input, the created data will be the same. To produce pure \
       data, the [timing] component of the merlin response is being cropped. \
       This command is useful for end-to-end regression analyzis of the \
       ocamlmerlin responses. "
    in
    Cmd.info "regression" ~doc ~man
  in
  Cmd.v info regression_term

let main =
  Cmd.group ~default:performance_term (Cmd.info "merl-an" ~man)
    [ performance; regression ]

let () = exit (Cmd.eval main)
