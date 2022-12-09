(** Type for logging. The logs should be persisted with [Data.persist_logs]*)
type t = Error of string | Warning of string | Log of string

val to_yojson : t -> Yojson.Safe.t
val pp : Format.formatter -> t -> unit
