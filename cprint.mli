val print_declarations : Format.formatter -> CAST.var_declaration list -> unit

val print_locator : Format.formatter -> string -> int -> int -> int -> int -> unit

val print_ast : Format.formatter -> CAST.var_declaration list -> unit

val print_ast_close_to_C : Format.formatter -> CAST.var_declaration list -> unit
