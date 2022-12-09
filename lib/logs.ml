type t = Error of string | Warning of string | Log of string
[@@deriving to_yojson]

let pp ppf data =
  Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))
