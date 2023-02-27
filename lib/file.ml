open! Import

type t = Fpath.t

let yojson_of_t file = `String (Fpath.to_string file)
let pp = Fpath.pp
let filename = Fpath.to_string

let get_files ~extensions paths =
  let open Result.Syntax in
  let traverse =
    let do_exclude path =
      let excluded_folders = [ "_build"; "_opam"; ".opam" ] in
      let folder_name = Fpath.to_string @@ Fpath.base path in
      not (List.mem folder_name excluded_folders)
    in
    `Sat (fun path -> Ok (do_exclude path))
  in
  let* files =
    Bos.OS.Path.fold ~traverse
      (fun file acc ->
        let has_ext =
          List.fold_left
            (fun b ext -> b || Fpath.has_ext ext file)
            false extensions
        in
        if has_ext then file :: acc else acc)
      [] paths
  in
  match files with
  | [] ->
      let msg =
        Printf.sprintf
          "The provided proj_dir doesn't contain any files with extensions %s.\n"
          (String.concat ", " extensions)
      in
      Error (`Msg msg)
  | _ -> Ok files

let parse_impl sourcefile =
  let file = Fpath.to_string sourcefile in
  let ic = open_in file in
  Fun.protect
    ~finally:(fun () -> close_in_noerr ic)
    (fun () ->
      let lb = Lexing.from_channel ic in
      Ppxlib.Location.init lb file;
      Ppxlib.Parse.implementation lb)
