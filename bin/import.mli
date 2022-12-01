module Result : sig
  include module type of Stdlib.Result

  module Syntax : sig
    val ( let+ ) : ('a, 'b) t -> ('a -> 'c) -> ('c, 'b) t
    val ( let* ) : ('a, 'b) t -> ('a -> ('c, 'b) t) -> ('c, 'b) t
  end
end

module List : sig
  include module type of Stdlib.List

  val fold_over_product :
    l1:'a t -> l2:'b t -> init:'c -> ('c -> 'a * 'b -> 'c) -> 'c
end

module Location : sig
  include module type of Ppxlib.Location

  type edge = Left | Right

  val print_edge : edge -> Format.formatter -> t -> unit
  val to_yojson : t -> Yojson.Safe.t
end
