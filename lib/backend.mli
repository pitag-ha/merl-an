(* module Logs :
     sig
       type t = Error of string | Warning of string | Log of string
     end

   type t
   val all_files : t -> Fpath.t list
   (* val add_data :
     ?perf:Performance.t ->
     ?resp:Query_response.t ->
     ?cmd:Command.t -> ?metadata:Metadata.t -> ?log:Logs.t -> t -> unit *)
   val dump : dump_dir:Fpath.t -> t -> unit
   val update_analysis_data :
     id:int ->
     responses:Merlin.Response.t list ->
     cmd:Merlin.Cmd.t ->
     file:File.t ->
     loc:Warnings.loc -> query_type:Merlin.Query_type.t -> t -> unit
   val update_log : log:Logs.t -> t -> unit
   val update_metadata :
     proj_path:Fpath.t ->
     merlin:Merlin.t -> query_time:float option -> t -> unit
   val create_empty : unit -> t *)

type kind = With_perf | Pure

module type T = sig
  type t

  val kind : kind
  val create_empty : unit -> t

  val update_analysis_data :
    t ->
    id:int ->
    responses:Merlin.Response.t list ->
    cmd:Merlin.Cmd.t ->
    file:File.t ->
    loc:Warnings.loc ->
    query_type:Merlin.Query_type.t ->
    unit

  val persist_logs : log:Logs.t -> t -> unit
  val dump : dump_dir:Fpath.t -> t -> unit
  val all_files : unit -> Fpath.t list

  val persist_metadata : t -> proj_paths:Fpath.t list -> merlin:Merlin.t -> query_time:float -> unit
end

module With_performance : T

module Pure : T
