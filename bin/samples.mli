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

val add_analysis_to_data :
  merlin:Merlin.t ->
  query_time:float ->
  repeats_per_sample:int ->
  Data.t ->
  t ->
  float
(** [add_analysis_to_data ~merlin ~query_time ~repeats_per_sample data samples]
    appends new analysis data to [data]. The data results from running [merlin]
    on the [samples] (notice that [samples] also contains info on the file and
    on the query type the samples are for); it runs the query
    [repeats_per_sample] times. The new data is appended to [data] as a
    side-effect. The return value is the updated [query_time] (which is
    important to analyze the performance of this tool itself). *)
