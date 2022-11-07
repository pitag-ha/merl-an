module Pprintast_org = Pprintast
open Ppxlib
open! Import

let char_size = 8
let int_chars = (Sys.int_size + (char_size - 1)) / char_size

let int_array_of_string str =
  let length = String.length str in
  let size = (length + (int_chars - 1)) / int_chars in
  let array = Array.make size 0 in
  for i = 0 to size - 1 do
    let int = ref 0 in
    for j = 0 to int_chars - 1 do
      let index = (i * int_chars) + j in
      if index < length then
        let code = Char.code str.[index] in
        let shift = j * char_size in
        int := !int lor (code lsl shift)
    done;
    array.(i) <- !int
  done;
  array

let parse_impl sourcefile =
  let ic = open_in sourcefile in
  Fun.protect
    ~finally:(fun () -> close_in_noerr ic)
    (fun () ->
      let lb = Lexing.from_channel ic in
      Ppxlib.Location.init lb sourcefile;
      Parse.implementation lb)

let stop_server merlin =
  (* FIXME: only stop the server if it was actually started (sample set could be empty) *)
  let command = merlin ^ " server stop-server" in
  match Sys.command command with
  | 255 -> ()
  | code -> failwith ("merlin exited with code " ^ string_of_int code)

let get_timing = function
  | `Assoc answer -> (
      match List.assoc "timing" answer with
      | `Assoc timing -> (
          match List.assoc "clock" timing with
          | `Int time -> time
          | _ -> failwith "merlin gave bad output")
      | _ -> failwith "merlin gave bad output")
  | _ -> failwith "merlin gave bad output"

let query ~query_time cmd =
  let start_time = Sys.time () in
  let ic = Unix.open_process_in cmd in
  match Yojson.Basic.from_channel ic with
  | json -> (
      match Unix.close_process_in ic with
      | Unix.WEXITED 0 ->
          let updated_query_time = query_time +. Sys.time () -. start_time in
          (json, updated_query_time)
      | Unix.WEXITED code ->
          failwith ("merlin exited with code " ^ string_of_int code)
      | _ -> failwith "merlin closed unexpectedly")
  | exception e ->
      print_endline "merlin server exception\n";
      ignore (Unix.close_process_in ic);
      raise e

let get_sample_data ~query_time cmd =
  let first_result, query_time = query ~query_time cmd in
  let first_timing = get_timing first_result in
  let rec repeat_query ~query_time timings max left_indices =
    match left_indices with
    | [] -> (List.rev timings, max)
    | _ :: tl ->
        let next_res, query_time = query ~query_time cmd in
        let next_timing = get_timing next_res in
        let max_timing = Int.max max next_timing in
        repeat_query ~query_time (next_timing :: timings) max_timing tl
  in
  let timings, max_timing =
    repeat_query ~query_time [ first_timing ] first_timing @@ List.init 9 Fun.id
  in
  (timings, max_timing, first_result, query_time)

module Timing_data = struct
  type t = int * Yojson.Basic.t

  let compare (fst, _) (snd, _) = Int.compare fst snd
end

module Timing_tree = Bin_tree.Make (Timing_data)

let init_merlin_cache ~query_time ~timing_data ~query_data ~sample_id_counter
    ~query_type ~file = function
  | [] -> Error (timing_data, query_data, sample_id_counter, query_time)
  | (hd, _) :: rest_samples ->
      let cmd = query_type.Data.Query_type.cmd hd file in
      (* TODO: only do this when running [ocamlmerlin server], not when runing [ocamlmerlin single] *)
      let _, query_time = query ~query_time cmd in
      Ok (rest_samples, query_time)

let add_data ~sample_id_counter ~sample_size ~query_type ~query_time timing_data
    query_data sourcefile =
  let open Result.Syntax in
  let file = Fpath.to_string sourcefile in
  match parse_impl file with
  | exception _ -> Error (timing_data, query_data, sample_id_counter, query_time)
  | ast ->
      let seed = int_array_of_string file in
      let state = Random.State.make seed in
      let sample_set =
        Cursor_loc.create_sample_set ~k:sample_size ~state
          ~nodes:query_type.Data.Query_type.nodes ast
      in
      let* samples_after_init, query_time =
        init_merlin_cache ~query_time ~timing_data ~query_data
          ~sample_id_counter ~query_type ~file sample_set
      in
      let rec loop ~query_time timing_data query_data sample_id samples =
        match samples with
        | [] -> (timing_data, query_data, sample_id, query_time)
        | (loc, _) :: rest ->
            let cmd = query_type.Data.Query_type.cmd loc file in
            let timings, max_timing, merlin_reply, query_time =
              get_sample_data ~query_time cmd
            in
            let timing =
              {
                Data.Timing.timings;
                max_timing;
                file_name = file;
                query_type_name = query_type.Data.Query_type.name;
                sample_id;
              }
            in
            let response = { Data.Query_info.sample_id; merlin_reply; loc } in
            loop ~query_time (timing :: timing_data) (response :: query_data)
              (sample_id + 1) rest
      in
      Ok
        (loop ~query_time timing_data query_data (sample_id_counter + 1)
           samples_after_init)

let get_files ~extension path =
  (* TODO: exclude files in _build/ and _opam/ *)
  let open Result.Syntax in
  let* path = Fpath.of_string path in
  let traverse =
    let do_exclude path =
      let excluded_folders = [ "_build"; "_opam" ] in
      let folder_name = Fpath.to_string @@ Fpath.base path in
      not (List.mem folder_name excluded_folders)
    in
    `Sat (fun path -> Ok (do_exclude path))
  in
  let* files =
    Bos.OS.Path.fold ~traverse
      (fun file acc ->
        if Fpath.has_ext extension file then file :: acc else acc)
      [] [ path ]
  in
  match files with
  | [] ->
      Error
        (`Msg
          (Printf.sprintf
             "The provided PATH doesn't contain any files with %s-extension.\n"
             extension))
  | _ -> Ok files

let usage = "ocamlmerlin_bench MERLIN PATH PROJ_NAME"

let () =
  (* TODO: add arg for [server] / [single] switch. when [server] is chosen, make an ignored query run on each file before starting the data collection to populate the cache*)
  (* TODO: add arg to get the number of samples. defaults to 30 currently; better N% of AST size with a minimum of 2 (two instead of one since one of the two will be considered the cache initializer and will be ignored) *)
  (* TODO: add arg to get the number of repeats per concrete query. defaults to 10 *)
  (* TODO: add arg to get which query types the user wants to run. defaults to all supported query types *)
  (* TODO: add arg to decide whether to do the queries on ml- or mli-files. defaults to ml-files *)
  let sample_size = 30 in
  let args = ref [] in
  Arg.parse [] (fun arg -> args := arg :: !args) usage;
  let merlin, path, proj_name =
    match !args with
    | [ prof_name; path; merlin ] -> (merlin, path, prof_name)
    | _ ->
        Arg.usage [] usage;
        exit 1
  in
  let query_types =
    (* TODO: also add [complete-prefix] command. that's a little more complex than the other commands since, aside location and file name, it also requires a prefix of the identifier as input. *)
    let locate =
      let cmd location file =
        Format.asprintf
          "%s server locate -look-for ml -position '%a' -index 0 -filename %s \
           < %s"
          merlin (Cursor_loc.print End) location file file
      in
      { Data.Query_type.name = "locate"; cmd; nodes = [ Cursor_loc.Longident ] }
    in
    let case_analysis =
      let cmd location file =
        Format.asprintf
          "%s server case-analysis -start '%a' -end '%a' -filename %s < %s"
          merlin (Cursor_loc.print Start) location (Cursor_loc.print End)
          location file file
      in
      {
        Data.Query_type.name = "case-analysis";
        cmd;
        nodes = [ Cursor_loc.Expression; Cursor_loc.Var_pattern ];
      }
    in
    let type_enclosing =
      let cmd location file =
        Format.asprintf
          "%s server type-enclosing -position '%a' -filename %s < %s" merlin
          (Cursor_loc.print End) location file file
      in
      {
        Data.Query_type.name = "type-enclosing";
        cmd;
        nodes = [ Cursor_loc.Expression ];
      }
    in
    let occurrences =
      let cmd location file =
        Format.asprintf
          "%s server occurrences -identifier-at '%a' -filename %s < %s" merlin
          (Cursor_loc.print End) location file file
      in
      {
        Data.Query_type.name = "occurrences";
        cmd;
        nodes = [ Cursor_loc.Longident ];
      }
    in
    [ locate; case_analysis; type_enclosing; occurrences ]
  in
  match get_files ~extension:"ml" path with
  | Ok files ->
      let _num_samples, timing_data, query_data, query_time =
        let f (last_sample_id, timing_data, query_data, query_time)
            (file, query_type) =
          let sample_id_counter = last_sample_id + 1 in
          let updated_data =
            add_data ~query_time ~sample_id_counter ~sample_size ~query_type
              timing_data query_data file
          in
          let timing_data, query_data, id, query_time =
            match updated_data with
            | Ok (timing_data, query_data, sample_id, query_time) ->
                (timing_data, query_data, sample_id, query_time)
            | Error (timing_data, query_data, sample_id, query_time) ->
                (* TODO: for persistance of errors, don't just log this, but also add it to an error file *)
                Printf.eprintf
                  "Error: file %s couldn't be parsed and was ignored.\n"
                  (Fpath.to_string file);
                (timing_data, query_data, sample_id, query_time)
          in
          (id, timing_data, query_data, query_time)
        in
        List.fold_over_product ~l1:files ~l2:query_types ~init:(0, [], [], 0.) f
      in
      stop_server merlin;
      let target_folder = "data/" ^ proj_name in
      if not (Sys.file_exists target_folder) then
        (* FIXME: this isn't setting the permissions right *)
        (* TODO: if data for that project already exists, prompt the user if they want to override it *)
        Sys.mkdir target_folder (int_of_string "0x777");
      Data.dump ~formatter:Data.Timing.print
        ~filename:(target_folder ^ "/timing.json")
        timing_data;
      Data.dump ~formatter:Data.Query_info.print
        ~filename:(target_folder ^ "/query_info.json")
        query_data;
      let total_time = Sys.time () in
      let metadata = { Data.Metadata.total_time; query_time } in
      Data.dump ~formatter:Data.Metadata.print
        ~filename:(target_folder ^ "/metadata.json")
        [metadata];
      ()
  | Error (`Msg err) -> Printf.eprintf "%s" err
