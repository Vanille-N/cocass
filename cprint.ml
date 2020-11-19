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

let rec inline_code code =
    match snd code with
        | CBLOCK _ -> false
        | CEXPR expr -> inline_expr expr
        | CIF _ -> false
        | CWHILE _ -> false
        | CRETURN None -> true
        | CRETURN (Some ret) -> inline_expr ret
and inline_expr expr =
    match snd expr with
        | VAR _ -> true
        | CST _ -> true
        | STRING _ -> true
        | SET_VAR (_, expr) -> inline_expr expr
        | SET_ARRAY (_, index, value) -> (inline_expr index) && (inline_expr value)
        | CALL _ -> false
        | OP1 (_, expr) -> inline_expr expr
        | OP2 (_, lhs, rhs) -> (inline_expr lhs) && (inline_expr rhs)
        | CMP (_, lhs, rhs) -> (inline_expr lhs) && (inline_expr rhs)
        | EIF _ -> false
        | ESEQ _ -> false

let rec print_code_indent offset out code =
    match snd code with
        | CBLOCK (decl_lst, code_lst) -> (
            fprintf out "%sblock decl [\n" (indent offset);
            print_ast_indent (offset + 1) out decl_lst;
            fprintf out "%s] body {\n" (indent offset);
            List.iter (print_code_indent (offset + 1) out) code_lst;
            fprintf out "%s}\n" (indent offset);
        )
        | CEXPR expr -> (
            fprintf out "%sexpr (\n" (indent offset);
            print_expr_indent (offset + 1) out expr;
            fprintf out "%s)\n" (indent offset);
        )
        | CIF (cond, code_true, code_false) -> (
            fprintf out "%scond (\n" (indent offset);
            print_expr_indent (offset + 1) out cond;
            fprintf out "%s) do true {\n" (indent offset);
            print_code_indent (offset + 1) out code_true;
            fprintf out "%s} do false {\n" (indent offset);
            print_code_indent (offset + 1) out code_false;
            fprintf out "%s}\n" (indent offset);
        )
        | CWHILE (cond, code) -> (
            fprintf out "%scond (\n" (indent offset);
            print_expr_indent (offset + 1) out cond;
            fprintf out "%s) loop true {\n" (indent offset);
            print_code_indent (offset + 1) out code;
            fprintf out "%s}\n" (indent offset);
        )
        | CRETURN None -> fprintf out "%sret void\n" (indent offset)
        | CRETURN (Some ret) -> (
            fprintf out "%sret val (\n" (indent offset);
            print_expr_indent (offset + 1) out ret;
            fprintf out "%s)\n" (indent offset);
        )
and print_ast_indent offset out dec_lst =
    List.iter (function
        | CDECL (_, name) -> fprintf out "%svar name <%s>\n" (indent offset) (Pigment.green name)
        | CFUN (_, name, decs, code) -> (
            fprintf out "%sfunc name <%s> args [\n" (indent offset) (Pigment.red name);
            print_ast_indent (offset + 1) out decs;
            fprintf out "%s] body {\n" (indent offset);
            print_code_indent (offset + 1) out code;
            fprintf out "%s}\n" (indent offset)
        )
    ) dec_lst
and print_expr_indent offset out expr =
    match snd expr with
        | VAR name -> fprintf out "%sread <%s>\n" (indent offset) (Pigment.green name)
        | CST value -> fprintf out "%sconst int <%s>\n" (indent offset) (Pigment.blue (string_of_int value))
        | STRING str -> fprintf out "%sconst str <\"%s\">\n" (indent offset) (Pigment.blue (String.escaped str))
        | SET_VAR (name, expr) -> (
            fprintf out "%sassign <%s> val (\n" (indent offset) (Pigment.green name);
            print_expr_indent (offset + 1) out expr;
            fprintf out "%s)\n" (indent offset);
        )
        | SET_ARRAY (name, index, value) -> (
            fprintf out "%sassign <%s> index [\n" (indent offset) (Pigment.green name);
            print_expr_indent (offset + 1) out index;
            fprintf out "%s] val (\n" (indent offset);
            print_expr_indent (offset + 1) out value;
            fprintf out "%s)\n" (indent offset);
        )
        | CALL (fname, expr_lst) -> (
            fprintf out "%scall fn <%s> args (\n" (indent offset) (Pigment.red fname);
            List.iter (print_expr_indent (offset + 1) out) expr_lst;
            fprintf out "%s)\n" (indent offset);
        )
        | OP1 (op, expr) -> (
            fprintf out "%scall op <%s> args (\n" (indent offset) (Pigment.red (mon_op_repr op));
            print_expr_indent (offset + 1) out expr;
            fprintf out "%s)\n" (indent offset);
        )
        | OP2 (op, lhs, rhs) -> (
            fprintf out "%scall op <%s> args (\n" (indent offset) (Pigment.red (bin_op_repr op));
            print_expr_indent (offset + 1) out lhs;
            print_expr_indent (offset + 1) out rhs;
            fprintf out "%s)\n" (indent offset);
        )
        | CMP (op, lhs, rhs) -> (
            fprintf out "%scall op <%s> args (\n" (indent offset) (Pigment.red (cmp_op_repr op));
            print_expr_indent (offset + 1) out lhs;
            print_expr_indent (offset + 1) out rhs;
            fprintf out "%s)\n" (indent offset);
        )
        | EIF (cond, expr_true, expr_false) -> (
            fprintf out "%scond (\n" (indent offset);
            print_expr_indent (offset + 1) out cond;
            fprintf out "%s) val true (\n" (indent offset);
            print_expr_indent (offset + 1) out expr_true;
            fprintf out "%s) val false (\n" (indent offset);
            print_expr_indent (offset + 1) out expr_false;
            fprintf out "%s)\n" (indent offset);
        )
        | ESEQ exprs -> (
            fprintf out "%sseq {\n" (indent offset);
            List.iter (print_expr_indent (offset + 1) out) exprs;
            fprintf out "%s}\n" (indent offset);
        )

let print_declarations = print_ast_indent 0

let print_locator out nom fl fc ll lc =
    fprintf out "in file <%s> from %d:%d to %d:%d" nom fl fc ll lc

let print_ast = print_ast_indent 0
