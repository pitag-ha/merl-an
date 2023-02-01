let write_json_lines ~formatter ~file_path l =
  let oc = open_out file_path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr oc)
    (fun () ->
      let ppf = Format.formatter_of_out_channel oc in
      Format.pp_print_list ~pp_sep:Format.pp_print_newline formatter ppf l)
