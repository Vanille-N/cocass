val verbose : int ref

val reduce_exprs : bool ref

val info : string -> Error.locator option -> unit

val detail : string -> Error.locator option -> unit
