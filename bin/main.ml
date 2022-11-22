open! Import
module Pprintast_org = Pprintast

(* FIXME: where was I using this?? *)
module Timing_tree = Bin_tree.Make (struct
  type t = int * Yojson.Basic.t

  let compare (fst, _) (snd, _) = Int.compare fst snd
end)

let usage = "ocamlmerlin_bench MERLIN_PATH PROJ_PATH PROJ_NAME"

let () =
  (* TODO: add arg for [server] / [single] switch. when [server] is chosen, make an ignored query run on each file before starting the data collection to populate the cache*)
  (* TODO: add arg to get the number of samples. defaults to 30 currently; better N% of AST size with a minimum of 2 (two instead of one since one of the two will be considered the cache initializer and will be ignored) *)
  (* TODO: add arg to get the number of repeats per concrete query. defaults to 10 *)
  (* TODO: add arg to get which query types the user wants to run. defaults to all supported query types *)
  (* TODO: add arg to decide whether to do the queries on ml- or mli-files. defaults to ml-files *)
  let sample_size = 30 in
  let args = ref [] in
  Arg.parse [] (fun arg -> args := arg :: !args) usage;
  let merlin_path, proj_path, proj_name =
    match !args with
    | [ proj_name; proj_path; merlin_path ] ->
        (Fpath.v merlin_path, proj_path, proj_name)
    | _ ->
        Arg.usage [] usage;
        exit 1
  in
  let merlin_frontend = Merlin.Server in
  let merlin = Merlin.make merlin_path merlin_frontend in
  let query_types =
    (* TODO: also add [complete-prefix] command. that's a little more complex than the other commands since, aside location and file name, it also requires a prefix of the identifier as input. *)
    (* FIXME: access the query_types over a function that defaults to returning all query types but can be restricted *)
    Merlin.Query_type.all
  in
  let path = Fpath.v proj_path in
  match File.get_files ~extension:"ml" path with
  | Ok files ->
      let add_data ((timing_data, query_data, qt), id_counter) (file, query_type)
          =
        match Samples.generate ~sample_size ~id_counter file query_type with
        | None -> ((timing_data, query_data, qt), id_counter)
        (* TODO: add to error data: "Error: file %s couldn't be parsed and was ignored.\n" *)
        | Some (samples, new_id_counter) ->
            ( Samples.add_benchmarks ~merlin ~query_time:qt
                ~current_data:(timing_data, query_data) samples,
              new_id_counter )
      in
      let (timing_data, query_data, total_query_time), _last_sample_id =
        List.fold_over_product ~l1:files ~l2:query_types
          ~init:(([], [], 0.), 0)
          add_data
      in
      let target_folder = "data/" ^ proj_name in
      if not (Sys.file_exists target_folder) then
        (* FIXME: this isn't setting the permissions right *)
        (* TODO: if data for that project already exists, prompt the user if they want to override it *)
        Sys.mkdir target_folder (int_of_string "0x777");
      (* FIXME: remove the following 3 lines and instead create the files and check that they're readable before running the benchmarks!*)
      print_endline "here";
      let oc = open_out (target_folder ^ "/timing.json") in
      close_out_noerr oc;
      print_endline "there";
      Data.dump ~formatter:Data.Timing.print
        ~filename:(target_folder ^ "/timing.json")
        timing_data;
      Data.dump ~formatter:Data.Query_info.print
        ~filename:(target_folder ^ "/query_info.json")
        query_data;
      let total_time = Sys.time () in
      let metadata =
        { Data.Metadata.total_time; query_time = total_query_time; merlin }
      in
      Data.dump ~formatter:Data.Metadata.print
        ~filename:(target_folder ^ "/metadata.json")
        [ metadata ];
      Merlin.stop_server merlin
  | Error (`Msg err) -> Printf.eprintf "%s" err
