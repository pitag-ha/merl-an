open Cmdliner

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

let analyze ~backend (`Repeats repeats) (`Cache cache_workflow)
    (`Merlin merlin_path) (`Proj_dirs proj_dirs) (`Dir_name data_dir)
    (`Sample_size sample_size) (`Query_types query_types)
    (`Extensions extensions) =
  match
    Merl_an.Workflows.analyze ~backend ~repeats ~cache_workflow ~merlin_path
      ~proj_dirs ~data_dir ~sample_size ~query_types ~extensions
  with
  | Ok () -> ()
  | Error (`Msg err) ->
      Printf.eprintf "%s" err;
      exit 50

let performance_term =
  let backend =
    (module Merl_an.Backend.Performance : Merl_an.Backend.Data_tables)
  in
  Term.(
    const (analyze ~backend)
    $ Args.repeats_per_sample $ Args.cache_workflow $ Args.merlin
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

let behavior =
  let f (`No_full no_full) (`No_cat_data no_cat_data) =
    let config =
      { Merl_an.Backend.full = not no_full; category_data = not no_cat_data }
    in
    let backend = Merl_an.Backend.behavior config in
    analyze ~backend (`Repeats 1)
      (`Cache Merl_an.Merlin.Cache_workflow.Buffer_typed)
  in
  let pre_term = Term.(const f $ Args.no_full $ Args.no_cat_data) in
  let behavior_term =
    Term.(
      pre_term $ Args.merlin $ Args.proj_dirs $ Args.dir_name $ Args.sample_size
      $ Args.query_types $ Args.extensions)
  in
  let info =
    let doc =
      "Create a new pure data set to analyze ocamlmerlin on a given project. \
       The data is pure in the sense that if you run the command twice with \
       the same input, the created data will be the same. To produce pure \
       data, the [timing] component of the merlin response is being cropped. \
       This command is useful for end-to-end behavior analyzis of the \
       ocamlmerlin responses. "
    in
    Cmd.info "behavior" ~doc ~man
  in
  Cmd.v info behavior_term

let benchmark =
  let backend =
    (module Merl_an.Backend.Benchmark : Merl_an.Backend.Data_tables)
  in
  let regression_term =
    Term.(
      const
        (analyze ~backend (`Repeats 1)
           (`Cache Merl_an.Merlin.Cache_workflow.Buffer_typed))
      $ Args.merlin $ Args.proj_dirs $ Args.dir_name $ Args.sample_size
      $ Args.query_types $ Args.extensions)
  in
  let info =
    let doc = "TODO" in
    Cmd.info "benchmark" ~doc ~man
  in
  Cmd.v info regression_term

let main =
  Cmd.group ~default:performance_term (Cmd.info "merl-an" ~man)
    [ performance; behavior; benchmark ]

let () = exit (Cmd.eval main)
