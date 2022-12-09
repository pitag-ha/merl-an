open! Import

(* FIXME: once the tables structure is improved, this type should be split into several types and renamed *)
type sample = {
  id : int;
  responses : Merlin.Response.t list;
  cmd : Merlin.Cmd.t;
  file : File.t;
  loc : Warnings.loc;
  query_type : Merlin.Query_type.t;
}

module Make (B : Backend.Data_tables) = struct
  (* TODO: should probably also contain `repeats` and all the other means of configuration *)
  type t = { dump_dir : Fpath.t; mutable content : B.t }

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

  let init dump_dir =
    create_dir_recursively dump_dir;
    let tables = B.create_empty () in
    let data_files = B.all_files () in
    create_files dump_dir data_files;
    if some_file_isnt_writable dump_dir data_files then (
      Format.eprintf "It's not possible to write to the data files\n%!";
      exit 20)
    else { dump_dir; content = tables }

  let update { content; _ } { id; responses; cmd; file; loc; query_type } =
    B.update_analysis_data ~id ~responses ~cmd ~file ~loc ~query_type content

  let persist_logs ~log { content; _ } = B.persist_logs ~log content
  let wrap_up { content; dump_dir } = B.wrap_up content ~dump_dir
  let dump { dump_dir; content } = B.dump ~dump_dir content
end