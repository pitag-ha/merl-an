open! Import

type sample = { id : int; sample : Location.t * Ppxlib.Longident.t option }

type t = {
  samples : sample list;
  file : File.t;
  query_type : Merlin.Query_type.t;
}

let file_traversal ~random_state query_type =
  let open Ppxlib in
  object
    inherit
      [(Location.t * Longident.t option) Reservoir.t * bool] Ast_traverse.fold as super

    (* Possible FIXME: a longident such as [M.f] is only taken into account once all together as opposed to splitting it into [M] and [f]. to fix that, the parsing of the longident would have to be done manually (as opposed to further recursing it) in order to remember their individual location, which isn't reflected in the AST node*)
    method! longident_loc { loc = new_loc; txt = new_longident }
        (reservoir, in_vb) =
      if Merlin.Query_type.(has_target query_type Longident) then
        let new_reservoir =
          Reservoir.update ~random_state reservoir (new_loc, Some new_longident)
        in
        (new_reservoir, in_vb)
      else (reservoir, in_vb)

    method! expression e (reservoir, in_vb) =
      if Merlin.Query_type.(has_target query_type Expression) then
        let new_reservoir =
          Reservoir.update ~random_state reservoir (e.pexp_loc, None)
        in
        super#expression e (new_reservoir, in_vb)
      else super#expression e (reservoir, in_vb)

    method! value_binding vb (reservoir, _) =
      super#value_binding vb (reservoir, true)

    method! pattern p (reservoir, in_vb) =
      match
        ( Merlin.Query_type.(has_target query_type Var_pattern),
          in_vb,
          p.ppat_desc )
      with
      | true, false, Ppat_var { txt = _; loc } ->
          let new_reservoir =
            Reservoir.update ~random_state reservoir (loc, None)
          in
          super#pattern p (new_reservoir, false)
      | _ -> super#pattern p (reservoir, false)
  end

let generate ~sample_size ~id_counter file query_type =
  match File.parse_impl file with
  | exception _ -> (* FIXME: write to error buffer; *) None
  | ast ->
      (* FIXME: filter out locations that would return an error anyways (possibly similar to how patterns are filtered out for [case-analysis] if they belong to a value binding) *)
      (* TODO: add info to each sample about what kind of node it corresponds to (interesting for queries with more than one possible type of node) *)
      let random_state = Reservoir.Random_state.make file in
      let traverser = file_traversal ~random_state query_type in
      let reservoir, _ =
        let a =
          Reservoir.init ~placeholder:(Location.none, None) ~random_state
            sample_size
        in
        let is_in_value_binding = false in
        traverser#structure ast (a, is_in_value_binding)
      in
      let samples =
        let make_sample ~id sample = { id; sample } in
        Reservoir.get_samples ~make_sample ~id_counter reservoir
        (* match population_size with
           | 0 -> []
           | n when n <= k -> List.init population_size (fun i -> sample_array.(i))
           | n when n > k -> Array.to_list sample_array
           | _ -> failwith "negative population size"
           (* Cursor_loc.create_samples ~k:size ~random_state
              ~nodes:query_type.Merlin.Query_type.nodes ast *) *)
      in
      (*TODO: check whether I'm off by 1 or not in the returned new id_counter*)
      Some ({ samples; file; query_type }, id_counter + sample_size)

let get_some_sample_loc samples =
  match samples with [] -> None | { id = _; sample = loc, _ } :: _ -> Some loc

let analyze_one_sample ~query_time cmd =
  let rec repeat_query ~query_time timings max res n =
    match n with
    | 0 -> (List.rev timings, max, res)
    | n ->
        let next_res, query_time = Merlin.query ~query_time cmd in
        let next_timing = Merlin.Response.get_timing next_res in
        let max_timing = Int.max max next_timing in
        repeat_query ~query_time (next_timing :: timings) max_timing
          (Some next_res) (n - 1)
  in
  let timings, max_timing, last_res =
    repeat_query ~query_time [] Int.min_int None 10
  in
  (timings, max_timing, last_res, query_time)

let add_benchmarks ~merlin ~query_time ~current_data:(ts, qi)
    { samples; file; query_type } =
  match get_some_sample_loc samples with
  | None ->
      (* TODO: add to logs data that [file] doesn't have any sample for query_type  *)
      (ts, qi, query_time)
  | Some loc ->
      (* TODO: init merlin cache in Samples.add_benchmarks instead of here*)
      let query_time =
        Merlin.init_cache ~query_time ~query_type ~file ~loc merlin
      in
      let rec loop ~query_time ts qi samples =
        match samples with
        | [] -> (ts, qi, query_time)
        | { id; sample = loc, _ } :: rest ->
            let cmd = Merlin.Cmd.make ~query_type ~file ~loc merlin in
            let timings, max_timing, merlin_reply, query_time =
              analyze_one_sample ~query_time cmd
            in
            let timing =
              {
                Data.Timing.timings;
                max_timing;
                file;
                query_type;
                sample_id = id;
              }
            in
            let response =
              { Data.Query_info.sample_id = id; merlin_reply; loc }
            in
            loop ~query_time (timing :: ts) (response :: qi) rest
      in
      loop ~query_time ts qi samples
