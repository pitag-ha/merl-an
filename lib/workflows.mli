val analyze :
  backend:(module Backend.Data_tables) ->
  [< `Repeats of int ] ->
  [< `Cache of Merlin.Cache.t list ] ->
  [< `Merlin of string ] ->
  [< `Proj_dirs of string list ] ->
  [< `Dir_name of string option ] ->
  [< `Sample_size of int ] ->
  [< `Query_types of Merlin.Query_type.t list ] ->
  [< `Extensions of string list ] ->
  unit
