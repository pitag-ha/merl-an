module Make (Data : Map.OrderedType) : sig
  type 'a t

  val singleton : Data.t -> Data.t t
  val insert : Data.t -> Data.t t -> unit
  val sorted_iter : f:(Data.t -> unit) -> Data.t t -> unit
end
