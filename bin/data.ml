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
    file_name : string;
    query_type_name : string;
    sample_id : int;
  }
  [@@deriving yojson]

  let print ppf data =
    (* let timings_formatter =
         let pp_sep ppf () = Format.fprintf ppf ", " in
         Format.pp_print_list ~pp_sep (fun ppf num ->
             if num = max_timing then Format.fprintf ppf "%i" num
             (* FIXME: wanted to print this bolt to make it more visible, however making it bolt didn't work. *)
             else Format.fprintf ppf "%i" num)
       in
       Format.fprintf ppf "%i: [%a] %d %s" sample_id timings_formatter timings
         file_id query_type *)
    Format.fprintf ppf "%s" (Yojson.Safe.to_string (yojson_of_t data))
end

module Query_info = struct
  type t = {
    sample_id : int;
    merlin_reply : Yojson.Basic.t;
    loc : Cursor_loc.t;
  }

  let print ppf { sample_id; merlin_reply; loc } =
    let full_json =
      `Assoc
        [
          ("sample_id", `Int sample_id);
          ("reply", merlin_reply);
          ("loc", `String (Cursor_loc.pprint loc));
        ]
    in
    Format.fprintf ppf "%s" (Yojson.Basic.to_string full_json)
end

module File = struct
  type t = { file_id : int; filename : Fpath.t }

  let print ppf { file_id; filename } =
    let json =
      `Assoc
        [
          ("file_id", `Int file_id);
          ("filename", `String (Fpath.to_string filename));
        ]
    in
    Format.fprintf ppf "%s" (Yojson.Basic.to_string json)
end

module Query_type = struct
  (* FIXME: make Fpath.t out of the second parameter of [cmd] (it represents the filenmae) *)
  type t = {
    name : string;
    cmd : Ppxlib.Location.t -> string -> string;
    nodes : Cursor_loc.corr_node list;
  }
  [@@deriving yojson]

  let _print ppf data =
    Format.fprintf ppf "%s" (Yojson.Safe.to_string (yojson_of_t data))
end
