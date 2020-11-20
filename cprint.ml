open Cparse
open Format
module Pg = Pigment

let indent offset = String.make (offset*2) ' '
let bifurc = "  ├── "
let termin = "  └── "
let cont =   "  │   "
let blank =  "      "

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

let rec print_block printer offset out lst =
    match lst with
        | [] -> ()
        | [e] -> printer offset false out e
        | e::rest -> (
            printer offset true out e;
            print_block printer offset out rest
        )

let rec print_code_indent offset next out code =
    let curr_full = if next then bifurc else termin in
    let curr_empty = if next then cont else blank in
    match snd code with
        | CBLOCK (decl_lst, code_lst) -> (
            fprintf out "%sblock\n" (offset ^ curr_full ^ Pg.reset);
            print_ast_indent (offset ^ curr_empty ^ Pg.reset) true out decl_lst;
            fprintf out "%sbody\n" (offset ^ curr_empty ^ Pg.reset ^ termin);
            print_block print_code_indent (offset ^ curr_empty ^ Pg.reset ^ blank) out code_lst;
        )
        | CEXPR expr -> (
            fprintf out "%sexpr\n" (offset ^ curr_full ^ Pg.reset);
            print_expr_indent (offset ^ curr_empty ^ Pg.reset) false out expr;
        )
        | CIF (cond, code_true, code_false) -> (
            fprintf out "%scond\n" (offset ^ curr_full ^ Pg.yellow);
            print_expr_indent (offset ^ Pg.reset ^ curr_empty ^ Pg.yellow) true out cond;
            fprintf out "%scase true\n" (offset ^ curr_empty ^ Pg.yellow ^ bifurc ^ Pg.reset);
            print_code_indent (offset ^ curr_empty ^ Pg.yellow ^ cont ^ Pg.reset) false out code_true;
            fprintf out "%scase false\n" (offset ^ curr_empty ^ Pg.yellow ^ termin ^ Pg.reset);
            print_code_indent (offset ^ curr_empty ^ blank) false out code_false;
        )
        | CWHILE (cond, code) -> (
            fprintf out "%swhile\n" (offset ^ curr_full ^ Pg.purple);
            print_expr_indent (offset ^ Pg.reset ^ curr_empty ^ Pg.purple) true out cond;
            fprintf out "%srepeat\n" (offset ^ curr_empty ^ Pg.purple ^ termin ^ Pg.reset);
            print_code_indent (offset ^ curr_empty ^ blank) false out code;
        )
        | CRETURN None -> fprintf out "%sreturn void\n" (offset ^ curr_full ^ Pg.reset)
        | CRETURN (Some ret) -> (
            fprintf out "%sreturn\n" (offset ^ curr_full ^ Pg.reset);
            print_expr_indent (offset ^ curr_empty ^ Pg.reset) false out ret;
        )
and print_ast_indent offset next out dec_lst =
    let curr_full = if next then bifurc else termin in
    let curr_empty = if next then cont else blank in
    List.iter (function
        | CDECL (_, name) -> fprintf out "%svar <%s>\n" (offset ^ curr_full) (Pg.wrap_green name)
        | CFUN (_, name, decs, code) -> (
            fprintf out "%sfunc <%s>\n" (offset ^ curr_full) (Pg.wrap_red name);
            print_ast_indent (offset ^ curr_empty) true out decs;
            fprintf out "%sbody\n" (offset ^ blank ^ curr_full);
            print_code_indent (offset ^ blank ^ curr_empty) false out code;
        )
    ) dec_lst
and print_expr_indent offset next out expr =
    let curr_full = if next then bifurc else termin in
    let curr_empty = if next then cont else blank in
    match snd expr with
        | VAR name -> fprintf out "%svar <%s>\n" (offset ^ curr_full ^ Pg.reset) (Pg.wrap_green name)
        | CST value -> fprintf out "%sconst <%s>\n" (offset ^ curr_full ^ Pg.reset) (Pg.wrap_blue (string_of_int value))
        | STRING str -> fprintf out "%sconst <\"%s\">\n" (offset ^ curr_full ^ Pg.reset) (Pg.wrap_blue (String.escaped str))
        | SET_VAR (name, expr) -> (
            fprintf out "%sassign <%s>\n" (offset ^ curr_full ^ Pg.reset) (Pg.wrap_green name);
            print_expr_indent (offset ^ curr_empty ^ Pg.reset) false out expr;
        )
        | SET_ARRAY (name, index, value) -> (
            fprintf out "%sassign <%s>\n" (offset ^ curr_full ^ Pg.reset) (Pg.wrap_green name);
            fprintf out "%sindex\n" (offset ^ curr_empty ^ Pg.reset ^ bifurc);
            print_expr_indent (offset ^ curr_empty ^ Pg.reset ^ cont) false out index;
            fprintf out "%svalue\n" (offset ^ curr_empty ^ Pg.reset ^ termin);
            print_expr_indent (offset ^ curr_empty ^ Pg.reset ^ blank) false out value;
        )
        | CALL (fname, expr_lst) -> (
            fprintf out "%scall fn <%s>\n" (offset ^ curr_full ^ Pg.reset) (Pg.wrap_red fname);
            print_block print_expr_indent (offset ^ blank ^ Pg.reset) out expr_lst;
        )
        | OP1 (op, expr) -> (
            fprintf out "%scall op <%s>\n" (offset ^ curr_full ^ Pg.reset) (Pg.wrap_red (mon_op_repr op));
            print_expr_indent (offset ^ curr_empty ^ Pg.reset) false out expr;
        )
        | OP2 (op, lhs, rhs) -> (
            fprintf out "%scall op <%s>\n" (offset ^ curr_full ^ Pg.reset) (Pg.wrap_red (bin_op_repr op));
            print_expr_indent (offset ^ curr_empty ^ Pg.reset) true out lhs;
            print_expr_indent (offset ^ curr_empty ^ Pg.reset) false out rhs;
        )
        | CMP (op, lhs, rhs) -> (
            fprintf out "%scall op <%s>\n" (offset ^ curr_full ^ Pg.reset) (Pg.wrap_red (cmp_op_repr op));
            print_expr_indent (offset ^ curr_empty ^ Pg.reset) true out lhs;
            print_expr_indent (offset ^ curr_empty ^ Pg.reset) false out rhs;
        )
        | EIF (cond, expr_true, expr_false) -> (
            fprintf out "%sternary\n" (offset ^ curr_full ^ Pg.yellow);
            print_expr_indent (offset ^ curr_empty ^ Pg.yellow) true out cond;
            fprintf out "%sval true\n" (offset ^ curr_empty ^ Pg.yellow ^ bifurc ^ Pg.reset);
            print_expr_indent (offset ^ curr_empty ^ Pg.yellow ^ cont ^ Pg.reset) false out expr_true;
            fprintf out "%sval false\n" (offset ^ curr_empty ^ Pg.yellow ^ termin ^ Pg.reset);
            print_expr_indent (offset ^ curr_empty ^ blank ^ Pg.reset) false out expr_false;
        )
        | ESEQ exprs -> (
            fprintf out "%sseq\n" offset;
            print_block print_expr_indent (offset ^ blank) out exprs;
        )

let print_declarations = print_ast_indent "" false

let print_locator out nom fl fc ll lc =
    fprintf out "in file <%s> from %d:%d to %d:%d" nom fl fc ll lc

let print_ast = print_ast_indent "" false
