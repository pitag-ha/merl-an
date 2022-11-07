val dump :
  formatter:(Format.formatter -> 'a -> unit) ->
  filename:string ->
  'a list ->
  unit

module Timing : sig
  type t = {
    timings : int list;
    max_timing : int;
    file_name : string;
    query_type_name : string;
    sample_id : int;
  }

  val print : Format.formatter -> t -> unit
end

module Query_info : sig
  type t = {
    sample_id : int;
    merlin_reply : Yojson.Basic.t;
    loc : Cursor_loc.t;
  }

  val print : Format.formatter -> t -> unit
end

(* module File : sig
     type t = { file_id : int; filename : Fpath.t }

     val print : Format.formatter -> t -> unit
   end *)

module Query_type : sig
  type t = {
    name : string;
    cmd : Ppxlib.Location.t -> string -> string;
    nodes : Cursor_loc.corr_node list;
  }
end

module Metadata : sig
  (* TODO: add more metadata, such as:
     - the size of the AST per file
     -  ["repro" : { <sample_id> : <concrete cmd> } (for reproducability)
  *)
  type t = { total_time : float; query_time : float }

  val print : Format.formatter -> t -> unit
end
