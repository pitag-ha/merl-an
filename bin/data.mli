open! Import

val dump :
  formatter:(Format.formatter -> 'a -> unit) ->
  filename:string ->
  'a list ->
  unit
(** [dump ~formatter ~filename data] writes [data] to [filename] using
    [formatter] and separating the items in the [data] list by line breaks *)

module Timing : sig
  type t = {
    timings : int list;
    max_timing : int;
    file : File.t;
    query_type : Merlin.Query_type.t;
    sample_id : int;
  }
  (** Data keeping track of how long a certain merlin query takes on a certain
      sample *)
  (* FIXME: don't have all timings here. instead, add four fields here: one indicating the how maniest query it was for that sample; one with the ratio of max_time : min_time; two with the [cpu] resp [ppx] data from the merlin timing response of the query with the max timing. also, add the whole timing sub-json of the merlin response to query_info for each of the 10 queries of the sample *)

  val print : Format.formatter -> t -> unit
end

module Query_info : sig
  type t = {
    sample_id : int;
    merlin_reply : Merlin.Response.t option;
    loc : Location.t;
  }
  (** The whole merlin reply *)
  (* FIXME: add the whole timing sub-json of each of the 10 queries for each sample. *)
  (* instead of having [loc] here, have a separate data file for it *)

  val print : Format.formatter -> t -> unit
end

module Metadata : sig
  (* TODO: add more metadata, such as:
     - the size of the AST per file
     -  ["repro" : { <sample_id> : <concrete cmd> } (for reproducability)
  *)
  type t = { total_time : float; query_time : float; merlin : Merlin.t }
  (** Some metadata about the invokation of this tool itself *)

  val print : Format.formatter -> t -> unit
end
