(** Interface for optional warning messages *)

(** global variable for verbosity control *)
val verbose : int ref

(** should expressions be reduced (argument flag opt-in, mostly for testing) *)
val reduce_exprs : bool ref

(** printed if verbosity >= 1 *)
val info : Error.locator option -> string -> unit

(** printed if verbosity >= 2 *)
val detail : string -> unit
