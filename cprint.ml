open Cparse
open Format

let indent offset = String.make (offset*2) ' '

let mon_op_repr = function
    | M_MINUS -> "NEG"
    | M_NOT -> "NOT"
    | M_POST_INC -> "POST-INC"
    | M_POST_DEC -> "POST-DEC"
    | M_PRE_INC -> "PRE-INC"
    | M_PRE_DEC -> "PRE-DEC"

let bin_op_repr = function
    | S_MUL -> "MUL"
    | S_DIV -> "DIV"
    | S_ADD -> "ADD"
    | S_SUB -> "SUB"
    | S_INDEX -> "IDX"
    | S_MOD -> "MOD"

let cmp_op_repr = function
    | C_LT -> "LT"
    | C_LE -> "LE"
    | C_EQ -> "EQ"

let print_ast out dec_list =
    List.iter (function
        | CDECL(_, name) -> fprintf out "decl name <%s>\n" name
        | CFUN(_, name, decs, code) -> (
            fprintf out "func name <%s> args [\n" (Pigment.red name);
            print_declarations out decs;
            fprintf out "] body {\n";
            print_code out code;
            fprintf out "}\n"
        )
    ) dec_list
