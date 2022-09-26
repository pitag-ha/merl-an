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
