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
    file_id : int;
    query_type : string;
    sample_id : int;
  }

  let print ppf { timings; max_timing; file_id; query_type; sample_id } =
    let timings_formatter =
      Format.pp_print_list (fun ppf num ->
          if num = max_timing then Format.fprintf ppf "@{<bold>%i@}" num
          else Format.fprintf ppf "%i" num)
    in
    Format.fprintf ppf "%i: [%a] %d %s" sample_id timings_formatter timings
      file_id query_type
end

module Query_reply = struct
  type t = { sample_id : int; reply : Yojson.Basic.t }

  let print ppf { sample_id; reply } =
    Format.fprintf ppf "%i: %s" sample_id (Yojson.Basic.to_string reply)
end

module File = struct
  type t = { file_id : int; filename : Fpath.t }

  let print ppf { file_id; filename } =
    Format.fprintf ppf "%i: %s" file_id (Fpath.to_string filename)
end

module Query_type = struct
  type t = { query_type : string; exact_cmd : string }
end
