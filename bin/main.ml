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

let print_loc ppf loc =
  let open Location in
  let open Lexing in
  let pos = loc.loc_end in
  let line = pos.pos_lnum in
  let col = pos.pos_cnum - pos.pos_bol - 1 in
  Format.fprintf ppf "%i:%i" line col

let update_reservoir_sample ~size ~i ~w ~new_input ~input_index ~state samples =
  if input_index < size
    then let () = samples.(input_index) <- new_input in i, w
    else
      if input_index = i then
        let new_i =
          let r = Random.State.float state 1.0 in
          i + int_of_float (log r /. log (1. -. w)) + 1 in
        let random_index = Random.State.int state size in
        let () = samples.(random_index) <- new_input in
        let new_w =
          let r = Random.State.float state 1.0 in
          w *. exp ((log r) /. (float_of_int size)) in
        new_i, new_w
      else i, w

let enumerate ~k ~state ast =
  let folder =
    object
      inherit [int * Location.t Array.t * int * float] Ast_traverse.fold
      (* Possible FIXME: a longident such as [M.f] is only taken into account once all together as opposed to splitting it into [M] and [f]. to fix that, the parsing of the longident would have to be done manually (as opposed to further recursing it) in order to remember their individual location, which isn't reflected in the AST node*)
      method! longident_loc lid (nb, a, i, w) =
        let new_i, new_w = update_reservoir_sample ~size:k ~i ~w ~new_input:lid.loc ~input_index:nb ~state a in
        (nb + 1, a, new_i, new_w)
    end
  in
  let a = Array.make k Location.none in
  let initial_w =
    let r = Random.State.float state 1.0 in
    exp ((log r) /. (float_of_int k)) in
  let inital_i =
    let r = Random.State.float state 1.0 in
    k + int_of_float (log r /. log (1. -. initial_w)) + 1 in
  let population_size, sample_array, _, _ = folder#structure ast (0, a, inital_i, initial_w) in
  if k <= population_size then Array.to_list sample_array else List.init population_size (fun i -> sample_array.(i))


let parse_impl sourcefile =
  let ic = open_in sourcefile in
  Fun.protect
    ~finally:(fun () -> close_in_noerr ic)
    (fun () -> Parse.implementation (Lexing.from_channel ic))

let stop_server merlin =
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

let query cmd =
  let ic = Unix.open_process_in cmd in
  match Yojson.Basic.from_channel ic with
  | json -> (
      match Unix.close_process_in ic with
      | Unix.WEXITED 0 -> json
      | Unix.WEXITED code ->
          failwith ("merlin exited with code " ^ string_of_int code)
      | _ -> failwith "merlin closed unexpectedly")
  | exception e ->
      print_endline "merlin server exception\n";
      ignore (Unix.close_process_in ic);
      raise e

let get_sample_data cmd =
  let first_result = query cmd in
  let first_timing = get_timing first_result in
  let rec repeat_query timings max left_indices =
    match left_indices with
    | [] -> (List.rev timings, max)
    | _ :: tl ->
        let next_res = query cmd in
        let next_timing = get_timing next_res in
        let max_timing = Int.max max next_timing in
        repeat_query (next_timing :: timings) max_timing tl
  in
  let timings, max_timing =
    repeat_query [ first_timing ] first_timing @@ List.init 9 Fun.id
  in
  (timings, max_timing, first_result)

module Timing_data = struct
  type t = int * Yojson.Basic.t

  let compare (fst, _) (snd, _) = Int.compare fst snd
end

module Timing_tree = Bin_tree.Make (Timing_data)

let add_data ~merlin ~file_id ~sample_id_counter ~sample_size timing_data query_data
    sourcefile =
  let file = Fpath.to_string sourcefile in
  match parse_impl file with
  | exception _ -> Error (timing_data, query_data, sample_id_counter)
  | ast ->
      let seed = int_array_of_string file in
      let state = Random.State.make seed in
      let sample_locs = enumerate ~k:sample_size ~state ast in
      let rec loop timing_data query_data sample_id locations =
        match locations with
        | [] -> (timing_data, query_data, sample_id)
        | location :: rest ->
            let cmd =
              Format.asprintf
                "%s server locate -look-for ml -position '%a' -index 0 \
                 -filename %s < %s"
                merlin print_loc location file file
            in
            let timings, max_timing, reply = get_sample_data cmd in
            let timing =
              {
                Data.Timing.timings;
                max_timing;
                file_id;
                query_type = "FIXME!!!";
                sample_id;
              }
            in
            let response = { Data.Query_reply.sample_id; reply } in
            loop (timing :: timing_data) (response :: query_data)
              (sample_id + 1) rest
      in
      Ok (loop timing_data query_data (sample_id_counter + 1) sample_locs)

let get_files ~extension path =
  let open Result.Syntax in
  let* path = Fpath.of_string path in
  let* files =
    Bos.OS.Path.fold
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

let usage = "ocamlmerlin_tester MERLIN PATH"

let () =
  (* TODO: add arg for [server] / [single] switch. when [server] is chosen, make an ignored query run on each file before starting the data collection to populate the cache*)
  (* TODO: add arg to get the number of samples. defaults to 30 *)
  (* TODO: add arg to get the number of repeats per concrete query. defaults to 10 *)
  (* TODO: add arg to get which query types the user wants to run. defaults to all supported query types *)
  let sample_size = 30 in
  let args = ref [] in
  Arg.parse [] (fun arg -> args := arg :: !args) usage;
  let merlin, path =
    match !args with
    | [ path; merlin ] -> (merlin, path)
    | _ ->
        Arg.usage [] usage;
        exit 1
  in
  match get_files ~extension:"ml" path with
  | Ok files ->
      let timing_data, query_data, file_data, _num_samples =
        let rec loop ~last_sample_id ~last_file_id timing_data query_data
            file_data = function
          | [] -> (timing_data, query_data, file_data, last_sample_id)
          | file :: rest_files ->
              let file_id = last_file_id + 1 in
              let sample_id_counter = last_sample_id + 1 in
              let updated_data =
                add_data ~merlin ~file_id ~sample_id_counter ~sample_size timing_data
                  query_data file
              in
              let timing_data, query_data, id =
                match updated_data with
                | Ok (timing_data, query_data, sample_id) ->
                    (timing_data, query_data, sample_id)
                | Error (timing_data, query_data, sample_id) ->
                    (* TODO: for persistance of errors, don't just log this, but also add it to an error file *)
                    Printf.eprintf
                      "Error: file %s couldn't be parsed and was ignored."
                      (Fpath.to_string file);
                    (timing_data, query_data, sample_id)
              in
              let file_data =
                { Data.File.file_id; filename = file } :: file_data
              in
              loop ~last_sample_id:id ~last_file_id:file_id timing_data
                query_data file_data rest_files
        in
        loop ~last_sample_id:0 ~last_file_id:0 [] [] [] files
      in
      stop_server merlin;
      let _ = (timing_data, query_data, file_data) in
      Data.dump ~formatter:Data.Timing.print
        ~filename:"timing.json" timing_data;
      Data.dump ~formatter:Data.Query_reply.print
        ~filename:"query_replies.json" query_data;
      Data.dump ~formatter:Data.File.print
        ~filename:"files.json" file_data
  | Error (`Msg err) -> Printf.eprintf "%s" err
