val print_declarations : (Format.formatter * bool) -> CAST.var_declaration list -> unit

val print_locator : Format.formatter -> string -> int -> int -> int -> int -> unit

val print_ast : (Format.formatter * bool) -> CAST.var_declaration list -> unit
