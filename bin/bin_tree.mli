(* TODO: check if using a binary tree actually makes this more performant then e.g. a list which is optimized by the compiler*)

module Make (Data : Map.OrderedType) : sig
  type 'a t

  val singleton : Data.t -> Data.t t
  val insert : Data.t -> Data.t t -> unit
  val sorted_iter : f:(Data.t -> unit) -> Data.t t -> unit
end
