open! Import

module Make (Data : Map.OrderedType) = struct
  type 'a t = 'a node ref
  and 'a node = Leaf | Inner of 'a content
  and 'a content = { data : 'a; left : 'a t; right : 'a t }

  let make_inner data = Inner { data; left = ref Leaf; right = ref Leaf }
  let singleton data = ref (make_inner data)

  let insert new_ tree =
    let rec update_tree new_data current =
      match !current with
      | Leaf -> current := make_inner new_data
      | Inner { data = current; left; right } ->
          let child =
            if Data.compare new_data current > 0 then right else left
          in
          update_tree new_data child
    in
    update_tree new_ tree

  let sorted_iter ~f tree =
    let rec traverse ~f current =
      match !current with
      | Leaf -> ()
      | Inner { data; left; right } ->
          traverse ~f left;
          f data;
          traverse ~f right
    in
    traverse ~f tree
end
