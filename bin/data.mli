val dump :
  formatter:(Format.formatter -> 'a -> unit) ->
  filename:string ->
  'a list ->
  unit

module Timing : sig
  type t = {
    timings : int list;
    max_timing : int;
    file_id : int;
    query_type : string;
    sample_id : int;
  }

  val print : Format.formatter -> t -> unit
end

module Query_reply : sig
  type t = { sample_id : int; reply : Yojson.Basic.t }

  val print : Format.formatter -> t -> unit
end

module File : sig
  type t = { file_id : int; filename : Fpath.t }

  val print : Format.formatter -> t -> unit
end

module Query_type : sig
  type t = { query_type : string; exact_cmd : string }
end
