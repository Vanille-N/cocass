(** Expression optimization *)

(** Reduce some parts of an expression that can be known at compile-time.
  * Arguments:
  *  - (?) force reduction despite --no-reduce flag
  *  - list of known constant values
  *  - expression
  * Returns the reduced version
  *)
val redexp : ?force:bool -> (string * int) list -> CAST.loc_expr -> CAST.loc_expr

(** indicate absence of --no-reduce flag *)
val reduce_exprs : bool ref
