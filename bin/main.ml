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

let analyze ~backend (`Repeats repeats) (`Cache cache_workflows)
    (`Merlin merlin_path) (`Proj_dirs proj_dirs) (`Dir_name data_dir)
    (`Sample_size sample_size) (`Query_types query_types)
    (`Extensions extensions) =
  match
    Merl_an.Workflows.analyze ~backend ~repeats ~cache_workflows ~merlin_path
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
        (analyze ~backend (`Repeats 1)
           (`Cache [ Merl_an.Merlin.Cache.Buffer_typed ]))
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
