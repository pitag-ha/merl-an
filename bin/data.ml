open! Import

let dump ~formatter ~filename data =
  let oc = open_out filename in
  Fun.protect
    ~finally:(fun () -> close_out_noerr oc)
    (fun () ->
      let ppf = Format.formatter_of_out_channel oc in
      Format.pp_print_list ~pp_sep:Format.pp_print_newline formatter ppf data)

module Timing = struct
  type t = {
    timings : int list;
    max_timing : int;
    file : File.t;
    query_type : Merlin.Query_type.t;
    sample_id : int;
  }
  [@@deriving to_yojson]

  let print ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))
end

module Query_info = struct
  type t = {
    sample_id : int;
    merlin_reply : Merlin.Response.t option;
    loc : Location.t;
  }

  let print ppf { sample_id; merlin_reply; loc } =
    let reply =
      match merlin_reply with
      | None -> `String "none"
      | Some r -> Merlin.Response.to_yojson r
    in
    let full_json =
      `Assoc
        [
          ("sample_id", `Int sample_id);
          ("reply", reply);
          ("loc", `String (Format.asprintf "%a" Location.print loc));
        ]
    in
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string full_json)
end

module Metadata = struct
  (* TODO: add more metadata, such as:
     - the size of the AST per file
     -  ["repro" : { <sample_id> : <concrete cmd> } (for reproducability)
  *)
  type t = { total_time : float; query_time : float; merlin : Merlin.t }
  [@@deriving to_yojson]

  let print ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (to_yojson data))
end
