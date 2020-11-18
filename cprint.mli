val print_declarations : Format.formatter -> Cparse.var_declaration list -> unit

val print_locator : Format.formatter -> string -> int -> int -> int -> int -> unit

val print_ast : Format.formatter -> Cparse.var_declaration list -> unit
