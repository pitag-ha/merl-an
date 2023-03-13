open! Import

val analyze :
  backend:(module Backend.Data_tables) ->
  repeats:int ->
  cache_workflows:Merlin.Cache.t list ->
  merlin_path:string ->
  proj_dirs:string list ->
  data_dir:string option ->
  sample_size:int ->
  query_types:Merlin.Query_type.t list ->
  extensions:string list ->
  (unit, Rresult.R.msg) Result.t
