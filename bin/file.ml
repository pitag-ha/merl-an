open! Import

type t = Fpath.t

let to_yojson file = `String (Fpath.to_string file)
let pp = Fpath.pp
let filename = Fpath.to_string

let get_files ~extension path =
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

let parse_impl sourcefile =
  let file = Fpath.to_string sourcefile in
  let ic = open_in file in
  Fun.protect
    ~finally:(fun () -> close_in_noerr ic)
    (fun () ->
      let lb = Lexing.from_channel ic in
      Ppxlib.Location.init lb file;
      Ppxlib.Parse.implementation lb)
