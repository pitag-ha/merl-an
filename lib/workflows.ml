open! Import

let analyze ~backend:(module Backend : Backend.Data_tables) (`Repeats repeats)
    (`Cache cache_workflows) (`Merlin merlin_path) (`Proj_dirs proj_dirs)
    (`Dir_name data_dir) (`Sample_size sample_size) (`Query_types query_types)
    (`Extensions extensions) =
  let merlin_path = Fpath.v merlin_path in
  let merlins =
    List.mapi (fun i -> Merlin.make i merlin_path) cache_workflows
  in
  let proj_path dir = Fpath.v @@ Unix.realpath @@ dir in
  let open Result.Syntax in
  let* data_dir =
    match data_dir with
    | Some dir -> Ok (Fpath.v dir)
    | None ->
        let+ proj_name =
          match proj_dirs with
          | [] ->
            Error (`Msg "Expected at least one file or project to analyze")
          | [ proj_dir ] -> Ok (Fpath.basename @@ proj_path proj_dir)
          | proj_dir :: l ->
              let num = List.length l in
              let base = Fpath.basename @@ proj_path proj_dir in
              Ok (Format.sprintf "%s+%iothers" base num)
        in
        let ts = Int.to_string @@ Int.of_float @@ Unix.time () in
        Fpath.v ("data/" ^ proj_name ^ "+" ^ ts)
  in
  let module D = Data.Make (Backend) in
  let data = D.init merlins data_dir in
  let proj_paths = List.map proj_path proj_dirs in
  let* files = File.get_files ~extensions proj_paths in
  (*TODO: add terminal logging when getting the files: log number of files that are going to be benchmarked and, at the end, log how many that are.*)
  let side_effectively_add_data (qt, id_counter) (file, query_type) =
    match Samples.generate ~sample_size ~id_counter file query_type with
    | None ->
        let log =
          Logs.Warning
            (Format.sprintf "File %s couldn't be parsed and was ignored.\n"
               (Yojson.Safe.to_string @@ File.yojson_of_t file))
        in
        D.persist_logs ~log data;
        (qt, id_counter)
    | Some (samples, new_id_counter) -> (
        let update = D.update data in
        match
          Samples.analyze ~merlins ~query_time:qt ~repeats ~update samples
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
  (match List.find_opt Merlin.is_server merlins with
   | Some merlin -> Merlin.stop_server merlin
   | None -> ());
  Ok ()
