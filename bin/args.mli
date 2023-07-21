open Cmdliner

val merlin : [> `Merlin of string ] Term.t
(** Path to the ocamlmerlin executable. Defaults to [ocamlmerlin].*)

val proj_dirs : [> `Proj_dirs of string list ] Term.t
(** Directory path of the project, on which you want merlin to be analyzed.
    Defaults to [.] *)

val dir_name : [> `Dir_name of string option ] Term.t
(** Directory, in which the data is going to be stored. If the directory doesn't
    exist, it's created. If the same directory was already used in the past, the
    data will be overridden. Defaults to [data/<project>+<unix_timestamp>/].*)

val cache_workflows : [> `Cache of Merl_an.Merlin.Cache_workflow.t list ] Term.t
(** This tool supports different workflows simulating different states of the
    [ocamlmerlin] cache. The option [warm] simulates the situation of a cache
    that's initialized in terms of [cmi]-files, but not in terms of [cmt]-files:
    it uses the merlin server frontend and only initializes the cache via a
    general command using [cmt]-files. The option [freezing] simulates the
    situation of opening a new project and running a merlin query for the first
    time: it uses the single frontend. By default, this tool gathers data for
    the three workflows. You can restrict to less workflows via this option. *)
(* TODO: Add: The option [hot] simulates the situation of having a
    fully initialized cache: it uses the merlin server frontend and initializes
    the cache 100%.*)

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

val no_full : [> `No_full of bool ] Term.t
(** In [behavior] cmd, configures whether the whole Merlin response of each
    query will be dumped. *)

val no_cat_data : [> `No_cat_data of bool ] Term.t
(** In [behavior] cmd, configures whether the the following simplification of
    the Merlin response of each query will be dumped: Dump whether the return
    class of the response is a [return] containing a message, a return
    containing a JSON, a [failure], an [error], or an [exception]. *)
