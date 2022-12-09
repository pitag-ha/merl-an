open! Import

type t = { pure : bool; dump_dir : Fpath.t; mutable content : Tables.t }

let create_dir_recursively data_path =
  let dir = Fpath.to_string data_path in
  if Sys.file_exists dir then (
    (* possible TODO: prompt would be nicer *)
    Format.printf
      "Your data directory %a already exists. So the data in there will be \
       overriden. Sure you want that?? If not, you should interrupt now.\n\
       %!"
      Fpath.pp data_path;
    Unix.sleep 60)
  else
    let _ =
      Fpath.segs data_path |> List.map Fpath.v
      |> List.fold_left
           (fun last_dir b ->
             let dir =
               match last_dir with
               | Some last_dir -> Fpath.(append last_dir b)
               | None -> b
             in
             let () =
               try Sys.mkdir (Fpath.to_string dir) 0o777 with _ -> ()
             in
             Format.printf "dir: %a\n%!" Fpath.pp dir;
             Some dir)
           None
    in
    ()

let create_files dir =
  List.iter (fun fn ->
      let path = Fpath.(to_string @@ append dir fn) in
      let descr = Unix.openfile path [ Unix.O_CREAT ] 0o777 in
      Unix.close descr)

let some_file_isnt_writable data_path =
  List.exists (fun fn ->
      match open_out Fpath.(to_string @@ append data_path fn) with
      | exception _ -> true
      | oc ->
          close_out_noerr oc;
          false)

let init ~pure dump_dir =
  create_dir_recursively dump_dir;
  let tables = Tables.create_empty () in
  let data_files = Tables.all_files tables in
  create_files dump_dir data_files;
  if some_file_isnt_writable dump_dir data_files then (
    Format.eprintf "It's not possible to write to the data files\n%!";
    exit 20)
  else { pure; dump_dir; content = tables }

let update_tables ~updater data = updater data.content
let dump { dump_dir; content; pure = _ } = Tables.dump ~dump_dir content
