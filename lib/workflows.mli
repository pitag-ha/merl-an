open! Import

val analyze :
  backend:(module Backend.Data_tables) ->
  repeats:int ->
  cache_workflow:Merlin.Cache_workflow.t ->
  merlin_path:string ->
  proj_dirs:string list ->
  data_dir:string option ->
  sample_size:int ->
  query_types:Merlin.Query_type.t list ->
  filter_outliers:bool ->
  extensions:string list ->
  (unit, Rresult.R.msg) Result.t
