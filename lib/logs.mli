(** Type for logging. The logs should be persisted with [Data.persist_logs]*)
type t = Error of string | Warning of string | Log of string

val yojson_of_t : t -> Yojson.Safe.t
val pp : Format.formatter -> t -> unit
