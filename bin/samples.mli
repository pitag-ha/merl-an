type t
(** Represents a sample set on a fixed file for a fixed merlin query type. *)

val generate :
  sample_size:int ->
  id_counter:int ->
  File.t ->
  Merlin.Query_type.t ->
  (t * int) option
(** Given a source code file [f] and a merlin query type [qt], we consider all
    locations in the file that the given query type can act on. Let's call the
    set of all those locations [population]. Then,
    [generate ~sample_size ~id_counter f qt] generates a sample set of size
    [min sample_size <popultion size>] of that population with integer IDs
    starting at [id_counter]. In case of success, it returns the generated
    sample set together with an updated [id_counter]. *)

val add_benchmarks :
  merlin:Merlin.t ->
  query_time:float ->
  current_data:Data.Timing.t list * Data.Query_info.t list ->
  repeats_per_sample:int ->
  t ->
  Data.Timing.t list * Data.Query_info.t list * float
(** [add_benchmarks ~merlin ~query_time ~current_data ~repeats_per_sample samples]
    appends new performance data to [current_data] resulting from running
    [merlin] benchmarks on the [samples] (notice that [samples] also contains
    info on the file and on the query type the samples are for); it runs the
    query [repeats_per_sample] times. It returns the updated data together with
    updated [query_time] (the latter is important to analyze the performance of
    this tool itself). *)
