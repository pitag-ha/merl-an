open Ppxlib

type t = Location.t
type side = Start | End
type corr_node = Longident | Expression | Var_pattern [@@deriving yojson]

let print side ppf loc =
  let open Location in
  let open Lexing in
  let col, line =
    match side with
    | Start ->
        let pos = loc.loc_start in
        (pos.pos_cnum - pos.pos_bol, pos.pos_lnum)
    | End ->
        let pos = loc.loc_end in
        (pos.pos_cnum - pos.pos_bol - 1, pos.pos_lnum)
  in
  Format.fprintf ppf "%i:%i" line col

let pprint loc = Format.asprintf "%a" Location.print loc

let update_reservoir_sample ~size ~i ~w ~new_loc ?new_longident ~input_index
    ~state samples =
  if input_index < size then
    let () = samples.(input_index) <- (new_loc, new_longident) in
    (i, w)
  else if input_index = i then
    let new_i =
      let r = Random.State.float state 1.0 in
      i + int_of_float (log r /. log (1. -. w)) + 1
    in
    let random_index = Random.State.int state size in
    let () = samples.(random_index) <- (new_loc, new_longident) in
    let new_w =
      let r = Random.State.float state 1.0 in
      w *. exp (log r /. float_of_int size)
    in
    (new_i, new_w)
  else (i, w)

let create_sample_set ~k ~state ~nodes ast =
  (* FIXME: filter out locations that would return an error anyways (possibly similar to how patterns are filtered out for [case-analysis] if they belong to a value binding) *)
  (* TODO: add info to each sample about what kind of node it corresponds to (interesting for queries with more than one possible type of node) *)
  let folder =
    object
      inherit
        [int * (Location.t * Longident.t option) Array.t * int * float * bool] Ast_traverse
                                                                               .fold as super

      (* Possible FIXME: a longident such as [M.f] is only taken into account once all together as opposed to splitting it into [M] and [f]. to fix that, the parsing of the longident would have to be done manually (as opposed to further recursing it) in order to remember their individual location, which isn't reflected in the AST node*)
      method! longident_loc { loc = new_loc; txt = new_longident }
          (nb, a, i, w, in_vb) =
        if List.mem Longident nodes then
          let new_i, new_w =
            update_reservoir_sample ~size:k ~i ~w ~new_loc ~new_longident
              ~input_index:nb ~state a
          in
          (nb + 1, a, new_i, new_w, in_vb)
        else (nb, a, i, w, in_vb)

      method! expression e (nb, a, i, w, in_vb) =
        if List.mem Expression nodes then
          let new_i, new_w =
            update_reservoir_sample ~size:k ~i ~w ~new_loc:e.pexp_loc
              ~input_index:nb ~state a
          in
          super#expression e (nb + 1, a, new_i, new_w, in_vb)
        else super#expression e (nb, a, i, w, in_vb)

      method! value_binding vb (nb, a, i, w, _) =
        super#value_binding vb (nb, a, i, w, true)

      method! pattern p (nb, a, i, w, in_vb) =
        match (List.mem Var_pattern nodes, in_vb, p.ppat_desc) with
        | true, false, Ppat_var { txt = _; loc } ->
            let new_i, new_w =
              update_reservoir_sample ~size:k ~i ~w ~new_loc:loc ~input_index:nb
                ~state a
            in
            super#pattern p (nb + 1, a, new_i, new_w, false)
        | _ -> super#pattern p (nb, a, i, w, false)
    end
  in
  let a = Array.make k (Location.none, None) in
  let initial_w =
    let r = Random.State.float state 1.0 in
    exp (log r /. float_of_int k)
  in
  let inital_i =
    let r = Random.State.float state 1.0 in
    k + int_of_float (log r /. log (1. -. initial_w)) + 1
  in
  let population_size, sample_array, _, _, _ =
    folder#structure ast (0, a, inital_i, initial_w, false)
  in
  match population_size with
  | 0 ->
      let _ = print_endline "empty population" in
      []
  | x when x <= k ->
      let () = print_endline "small population" in
      List.init population_size (fun i -> sample_array.(i))
  | x when x > k ->
      let () = print_endline "big population" in
      Array.to_list sample_array
  | _ -> failwith "negative population size"
