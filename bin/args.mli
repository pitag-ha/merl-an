open! Merl_an.Import
open Cmdliner

val merlin : [> `Merlin of string ] Term.t
(** Path to the ocamlmerlin executable. Defaults to [ocamlmerlin].*)

val proj_dir : [> `Proj_dir of string ] Term.t
(** Directory path of the project, on which you want merlin to be analyzed.
    Defaults to [.] *)

val dir_name : [> `Dir_name of string option ] Term.t
(** Directory, in which the data is going to be stored. If the directory doesn't
    exist, it's created. If the same directory was already used in the past, the
    data will be overridden. Defaults to [data/<project>+<unix_timestamp>/].*)

val cold : [> `Cold of bool ] Term.t
(** By default, the merlin frontend [server] is being used and its cache is
    being initialized before collecting the data. That simulates a user doing
    lots of merlin queries without modifying the source code in between. If you
    want to simluate a user, who modifies the source code each time between two
    merlin queries, use this flag: it switches the frontend to [single], which
    is a similar behavior to using [server] without cache .*)

val sample_size : [ `Sample_size of int ] Term.t
(** Number of samples per file. Defaults to 30.*)
(* FIXME: Make that a relative numer: relative to the size of the file. *)

val query_types : [> `Query_types of Merl_an.Merlin.Query_type.t list ] Term.t
(** List of merlin commands you want to be analyzed. Defaults to all of them. *)

val extensions : [> `Extensions of string list ] Term.t
(** List of file extensions you want this tool to analyze data for. Options are
    [ml] and [mli]. Defaults to both.*)

val repeats_per_sample : [> `Repeats of int ] Term.t
(** Number of times you want the same query to be run on the same sample. The
    higher that number, the better to analyze variance. Defaults to 10.*)
