type t
(** Represents a source code file in the code base being benchmarked *)

val to_yojson : t -> Yojson.Safe.t
val pp : Format.formatter -> t -> unit

val filename : t -> string
(** Returns the name of a file *)

val get_files :
  extensions:string list -> Fpath.t list -> (t list, Rresult.R.msg) result
(** [get_files ~extension dir] produces the list of all files with extension
    [extension] inside [dir] *)

val parse_impl : t -> Ppxlib.Parsetree.structure
(** Parses a source code file into an AST *)
