open! Import

module Performance : sig
  type t = {
    sample_id : int;
    timings : int list;
    max_timing : int;
    file : File.t;
    query_type : Merlin.Query_type.t;
    loc : Location.t;
  }
  (** Data needed for performance analysis. *)
end

module Query_response : sig
  type t = { sample_id : int; merlin_reply : Merlin.Response.t option }
  (** The whole merlin reply of each query *)
end

module Metadata : sig
  (* TODO: add more metadata, such as:
     - the size of the AST per file
  *)
  type t
  (** Some metadata about how the analysis data has been created, such as info
      about the merlin executable, the concrete version of the source code and
      info about the performance of the data creation process itself. *)

  val create : merlin:Merlin.t -> total_query_time:float -> proj_dir:string -> t
  (** Creates a metadata value. Parts of that metadata comes from the arguments
      of the function, parts are added by the function. Among others, also the
      total time of the process is added, so this function should be called at
      the end of process. *)
end

module Command : sig
  type t = { sample_id : int; cmd : Merlin.Cmd.t }
  (** The concrete merlin commands that are run to create the data. *)
end

module Error : sig
  type t = string
end

type t
(** The data that's being collected by the tool. Consists of two pieces of
    information: the directory, in which the data should be persisted in the end
    (unmutable) and the data that's being collected step by step by the tool
    (mutable). *)

val init : Fpath.t -> t
(** Returns an empty [t] value with mutable content. The provided path is the
    path of the directory, inside which the data will be persisted as
    json-line-files. *)

val update :
  ?perf:Performance.t ->
  ?resp:Query_response.t ->
  ?cmd:Command.t ->
  ?err:Error.t ->
  ?metadata:Metadata.t ->
  t ->
  unit
(** Updates the respective parts of the data. *)

val dump : t -> unit
(** [dump data] writes the content of [data] into json-line files inside the
    directory of [data]. *)
