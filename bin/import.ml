module Result = struct
  include Stdlib.Result

  module Syntax = struct
    let ( let+ ) x f = Result.map f x
    let ( let* ) x f = Result.bind x f
  end
end

module List = struct
  include Stdlib.List

  let fold_over_product ~l1 ~l2 ~init f =
    List.fold_left
      (fun outer_acc x ->
        List.fold_left (fun inner_acc y -> f inner_acc (x, y)) outer_acc l2)
      init l1
end

module Location = struct
  include Ppxlib.Location

  type edge = Left | Right

  let print_edge e ppf loc =
    (* let open Lexing in *)
    let col, line =
      match e with
      | Left ->
          let pos = loc.loc_start in
          (pos.pos_cnum - pos.pos_bol, pos.pos_lnum)
      | Right ->
          let pos = loc.loc_end in
          (pos.pos_cnum - pos.pos_bol - 1, pos.pos_lnum)
    in
    Format.fprintf ppf "%i:%i" line col

  let to_yojson loc = `String (Format.asprintf "%a" print loc)
end
