module Cache : sig
  (** Kind of [ocamlmerlin] cache workflow to be used when running
      [ocamlmerlin]. [Hot] corresponds to using the server frontend and a 100%
      initialized cache; [Warm] corresponds to using the server frontend and a
      partily initialized cache; [Freezing] corresponds to using the single
      frontend. *)
  type t = (*Hot |*) Warm | Freezing

  val yojson_of_t : t -> Yojson.Safe.t
  val to_string : t -> string

  val all : t list
  (** Contains all supported cache workflows. *)
end

type t
(** Configuration details and metadata about the [ocamlmerlin] to be used *)

val pp : Format.formatter -> t -> unit
val yojson_of_t : t -> Yojson.Safe.t

val make : int -> ?comment:string -> Fpath.t -> Cache.t -> t
(** Create a [t] value by providing the path of where your [ocamlmerlin]
    executable lives and the frontend you want to be used and the id you want to
    attach to it. *)

val get_id : t -> int
(** Get the idea of your merlin instance *)

val is_server : t -> bool
(** Returns [true] if the frontend is [Server] and [false] if it's [Single] *)

module Query_type : sig
  (** The [ocamlmerlin] queries that this tool can create analysis data for *)
  type t = Locate | Case_analysis | Type_enclosing | Occurrences

  val yojson_of_t : t -> Yojson.Safe.t
  val to_string : t -> string

  val all : t list
  (** Returns a list of all [ocamlmerlin] queries that this tool creates
      benchmark data for*)

  (** The AST node types that can serve as target for (s)ome of the query types
      in [t] *)
  type node = Longident | Expression | Var_pattern

  val has_target : t -> node -> bool
  (** [has_target query_type node] checks whether [query_type] can act on AST
      nodes of type [node] or not *)
end

module Response : sig
  type t
  (** Represents the response of an [ocamlmerlin] command *)

  val yojson_of_t : t -> Yojson.Safe.t

  val get_timing : t -> int
  (** Extracts the information about time consumption from an [ocamlmerlin]
      response *)

  val crop_timing : t -> t
  (** Removes the timing field from the merlin responce. Usefule when you want
      pure data, e.g. for regression testing. *)
end

module Cmd : sig
  type merlin

  type t
  (** Represents a concrete [ocamlmerlin] command including location and
      everything *)

  val yojson_of_t : t -> Yojson.Safe.t

  val make :
    query_type:Query_type.t -> file:File.t -> loc:Location.t -> merlin -> t
  (** [make ~query_type ~file ~loc merlin] creates a concrete [ocamlmerlin]
      command by providing the following: the query [query_type]; the target of
      the query, i.e. the source code [file] and the location [loc] inside that
      file; and a [Merlin.t] value [merlin] *)

  val run : query_time:float -> repeats:int -> t -> Response.t list * float
  (** [run ~query_time ~repeats cmd] runs the concrete [ocamlmerlin] command
      [cmd]. It runs that command [repeat] times in a row and returns the
      [repeats] responses together with the updated [query_time] (where
      [query_time] is the time spent so far on all [ocamlmerlin] queries) *)
end
with type merlin := t

val init_cache : query_time:float -> File.t -> t -> (float, Logs.t) Result.t
(** [init_cache file merlin] inits the [merlin] cache on [file]. This should be
    called if one of the frontends is [Server]. It inits the cache by running a
    global command on the file. In case of success, it returns the updated
    [query_time]. *)

val stop_server : t -> unit
(** Stops the [ocamlmerlin] server. This should be called at the end of the
    whole process, if one of the frontends is [Server]; does nothing if the
    frontend is [Single] *)
