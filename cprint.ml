open CAST
open Format

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
    | M_DEREF -> "DEREF"
    | M_ADDR -> "ADDR"

let bin_op_repr = function
    | S_MUL -> "MUL"
    | S_DIV -> "DIV"
    | S_ADD -> "ADD"
    | S_SUB -> "SUB"
    | S_INDEX -> "IDX"
    | S_MOD -> "MOD"
    | S_SHL -> "SHL"
    | S_SHR -> "SHR"
    | S_AND -> "AND"
    | S_OR -> "OR"
    | S_XOR -> "XOR"

let cmp_op_repr = function
    | C_LT -> "LT"
    | C_LE -> "LE"
    | C_EQ -> "EQ"
    | C_GT -> "GT"
    | C_GE -> "GE"
    | C_NE -> "NE"

let rec print_block printer offset out lst =
    match lst with
        | [] -> ()
        | [e] -> printer offset false out e
        | e :: rest -> (
            printer offset true out e;
            print_block printer offset out rest
        )

let unwrap = function
    | None -> raise Not_found
    | Some x -> x

let print_ast (out, color) code =
    let color_none = if color then Pigment.reset else "" in
    let color_fun = if color then Pigment.red_bold else "" in
    let color_var = if color then Pigment.green_bold else "" in
    let color_loop = if color then Pigment.purple_bold else "" in
    let color_cond = if color then Pigment.yellow_bold else "" in
    let color_const = if color then Pigment.blue_bold else "" in
    let color_ctrl = if color then Pigment.purple_bold else "" in
    let rec print_code_indent offset next out code =
        let curr_empty = if next then cont else blank in
        let curr_full = if next then bifurc else termin in
        match snd code with
            | CBLOCK (code_lst) -> (
                fprintf out "%sblock\n" (offset ^ curr_full ^ color_none);
                List.iter (print_code_indent (offset ^ color_none ^ curr_empty) true out) code_lst;
                fprintf out "%s(end)\n" (offset ^ curr_empty ^ termin ^ color_none);
            )
            | CLOCAL (decl_lst) -> (
                print_ast_indent (offset ^ color_none) true out decl_lst;
            )
            | CEXPR expr -> (
                fprintf out "%sexpr\n" (offset ^ curr_full ^ color_none);
                print_expr_indent (offset ^ curr_empty ^ color_none) false out (Reduce.redexp [] expr);
            )
            | CIF (cond, code_true, code_false) -> (
                fprintf out "%scond\n" (offset ^ curr_full ^ color_cond);
                print_expr_indent (offset ^ curr_empty ^ color_cond) true out (Reduce.redexp [] cond);
                fprintf out "%swhen true\n" (offset ^ curr_empty ^ color_cond ^ bifurc ^ color_none);
                print_code_indent (offset ^ curr_empty ^ color_cond ^ cont ^ color_none) false out code_true;
                fprintf out "%swhen false\n" (offset ^ curr_empty ^ color_cond ^ termin ^ color_none);
                print_code_indent (offset ^ curr_empty ^ blank) false out code_false;
            )
            | CWHILE (cond, code, finally, test_at_start) -> (
                fprintf out "%s%s\n" (offset ^ curr_full ^ color_loop) (if not test_at_start then "do-while" else "while");
                print_expr_indent (offset ^ color_none ^ curr_empty ^ color_loop) true out (Reduce.redexp [] cond);
                fprintf out "%srepeat\n" (offset ^ curr_empty ^ color_loop ^ bifurc ^ color_none);
                print_code_indent (offset ^ curr_empty ^ color_loop ^ cont ^ color_none) false out code;
                fprintf out "%sfinally\n" (offset ^ curr_empty ^ color_loop ^ termin ^ color_none);
                print_expr_indent (offset ^ curr_empty ^ blank) false out (Reduce.redexp [] finally);
            )
            | CRETURN None -> fprintf out "%sreturn%s void\n" (offset ^ curr_full ^ color_ctrl) color_none
            | CRETURN (Some ret) -> (
                fprintf out "%sreturn%s\n" (offset ^ curr_full ^ color_ctrl) color_none;
                print_expr_indent (offset ^ curr_empty ^ color_none) false out (Reduce.redexp [] ret);
            )
            | CBREAK -> fprintf out "%sbreak%s\n" (offset ^ curr_full ^ color_ctrl) color_none
            | CCONTINUE -> fprintf out "%scontinue%s\n" (offset ^ curr_full ^ color_ctrl) color_none
            | CSWITCH (e, cases, deflt) -> (
                fprintf out "%sswitch%s\n" (offset ^ curr_full ^ color_cond) color_none;
                print_expr_indent (offset ^ curr_empty ^ color_cond) true out (Reduce.redexp [] e);
                List.iter (fun (_, v, c) -> (
                    fprintf out "%scase %s%d%s\n" (offset ^ curr_empty ^ color_ctrl) color_const v color_none;
                    print_code_indent (offset ^ curr_empty ^ color_cond) true out c
                )) cases;
                fprintf out "%sdefault%s\n" (offset ^ curr_empty ^ color_ctrl) color_none;
                print_code_indent (offset ^ curr_empty ^ color_cond) false out deflt;
            )
            | CTHROW (exc, value) -> (
                fprintf out "%sthrow %s with\n" (offset ^ curr_full ^ color_ctrl) (color_fun ^ exc ^ color_none);
                print_expr_indent (offset ^ curr_empty ^ color_none) false out (Reduce.redexp [] value);
            )
            | CTRY (block, catch, finally) -> (
                fprintf out "%stry%s\n" (offset ^ curr_full ^ color_ctrl) color_none;
                print_code_indent (offset ^ curr_empty ^ color_ctrl) true out block;
                List.iter (fun (_, exc, bind, handle) ->
                    fprintf out "%scatch %s as %s\n" (offset ^ curr_empty ^ color_ctrl) (color_fun ^ exc ^ color_none) (color_var ^ bind ^ color_none);
                    print_code_indent (offset ^ curr_empty ^ color_ctrl) true out handle;
                ) catch;
                fprintf out "%sfinally%s\n" (offset ^ curr_empty ^ color_ctrl) color_none;
                print_code_indent (offset ^ curr_empty ^ color_ctrl) false out finally;
            )
    and print_ast_indent offset next out dec_lst =
        let curr_full = if next then bifurc else termin in
        let curr_empty = if next then cont else blank in
        List.iter (function
            | CDECL (_, name, None) -> fprintf out "%svar <%s>\n" (offset ^ curr_full) (color_var ^ name ^ color_none)
            | CDECL (_, name, Some init) -> (
                fprintf out "%svar <%s>\n" (offset ^ curr_full) (color_var ^ name ^ color_none);
                fprintf out "%sinit\n" (offset ^ curr_empty ^ termin);
                print_expr_indent (offset ^ curr_empty ^ blank) false out init;
            )
            | CFUN (_, name, decs, code) -> (
                fprintf out "%sfunc <%s>\n" (offset ^ curr_full) (color_fun ^ name ^ color_none);
                print_ast_indent (offset ^ curr_empty) true out decs;
                fprintf out "%sbody\n" (offset ^ blank ^ curr_full);
                print_code_indent (offset ^ blank ^ curr_empty) false out code;
            )
        ) dec_lst
    and print_expr_indent offset next out expr =
        let curr_full = if next then bifurc else termin in
        let curr_empty = if next then cont else blank in
        match snd expr with
            | VAR name -> fprintf out "%svar <%s>\n" (offset ^ curr_full ^ color_none) (color_var ^ name ^ color_none)
            | CST value -> fprintf out "%sconst <%s>\n" (offset ^ curr_full ^ color_none) (color_const ^ (string_of_int value) ^ color_none)
            | STRING str -> fprintf out "%sconst <%s>\n" (offset ^ curr_full ^ color_none) (color_const ^ "\"" ^ (String.escaped str) ^ "\"" ^ color_none)
            | SET_VAR (name, expr) -> (
                fprintf out "%sassign <%s>\n" (offset ^ curr_full ^ color_none) (color_var ^ name ^ color_none);
                print_expr_indent (offset ^ curr_empty ^ color_none) false out expr;
            )
            | SET_ARRAY (name, index, value) -> (
                fprintf out "%sassign <%s>\n" (offset ^ curr_full ^ color_none) (color_var ^ name ^ color_none);
                fprintf out "%sindex\n" (offset ^ curr_empty ^ color_none ^ bifurc);
                print_expr_indent (offset ^ curr_empty ^ color_none ^ cont) false out index;
                fprintf out "%svalue\n" (offset ^ curr_empty ^ color_none ^ termin);
                print_expr_indent (offset ^ curr_empty ^ color_none ^ blank) false out value;
            )
            | SET_DEREF (index, value) -> (
                fprintf out "%sassign\n" (offset ^ curr_full ^ color_none);
                fprintf out "%sderef\n" (offset ^ curr_empty ^ color_none ^ bifurc);
                print_expr_indent (offset ^ curr_empty ^ color_none ^ cont) false out index;
                fprintf out "%svalue\n" (offset ^ curr_empty ^ color_none ^ termin);
                print_expr_indent (offset ^ curr_empty ^ color_none ^ blank) false out value;
            )
            | OPSET_VAR (op, name, expr) -> (
                fprintf out "%sassign <%s> extended <%s>\n" (offset ^ curr_full ^ color_none) (color_var ^ name ^ color_none) (color_fun ^ (bin_op_repr op) ^ color_none);
                print_expr_indent (offset ^ curr_empty ^ color_none) false out expr;
            )
            | OPSET_ARRAY (op, name, index, value) -> (
                fprintf out "%sassign <%s> extended <%s>\n" (offset ^ curr_full ^ color_none) (color_var ^ name ^ color_none) (color_fun ^ (bin_op_repr op) ^ color_none);
                fprintf out "%sindex\n" (offset ^ curr_empty ^ color_none ^ bifurc);
                print_expr_indent (offset ^ curr_empty ^ color_none ^ cont) false out index;
                fprintf out "%svalue\n" (offset ^ curr_empty ^ color_none ^ termin);
                print_expr_indent (offset ^ curr_empty ^ color_none ^ blank) false out value;
            )
            | OPSET_DEREF (op, index, value) -> (
                fprintf out "%sassign extended <%s>\n" (offset ^ curr_full ^ color_none) (color_fun ^ (bin_op_repr op) ^ color_none);
                fprintf out "%sderef\n" (offset ^ curr_empty ^ color_none ^ bifurc);
                print_expr_indent (offset ^ curr_empty ^ color_none ^ cont) false out index;
                fprintf out "%svalue\n" (offset ^ curr_empty ^ color_none ^ termin);
                print_expr_indent (offset ^ curr_empty ^ color_none ^ blank) false out value;
            )
            | CALL (fname, expr_lst) -> (
                fprintf out "%scall fn <%s>\n" (offset ^ curr_full ^ color_none) (color_fun ^ fname ^ color_none);
                print_block print_expr_indent (offset ^ curr_empty ^ color_none) out expr_lst;
            )
            | OP1 (op, expr) -> (
                fprintf out "%scall op <%s>\n" (offset ^ curr_full ^ color_none) (color_fun ^ (mon_op_repr op) ^ color_none);
                print_expr_indent (offset ^ curr_empty ^ color_none) false out expr;
            )
            | OP2 (op, lhs, rhs) -> (
                fprintf out "%scall op <%s>\n" (offset ^ curr_full ^ color_none) (color_fun ^ (bin_op_repr op) ^ color_none);
                print_expr_indent (offset ^ curr_empty ^ color_none) true out lhs;
                print_expr_indent (offset ^ curr_empty ^ color_none) false out rhs;
            )
            | CMP (op, lhs, rhs) -> (
                fprintf out "%scall op <%s>\n" (offset ^ curr_full ^ color_none) (color_fun ^ (cmp_op_repr op) ^ color_none);
                print_expr_indent (offset ^ curr_empty ^ color_none) true out lhs;
                print_expr_indent (offset ^ curr_empty ^ color_none) false out rhs;
            )
            | EIF (cond, expr_true, expr_false) -> (
                fprintf out "%sternary\n" (offset ^ curr_full ^ color_cond);
                print_expr_indent (offset ^ curr_empty ^ color_cond) true out cond;
                fprintf out "%sval true\n" (offset ^ curr_empty ^ color_cond ^ bifurc ^ color_none);
                print_expr_indent (offset ^ curr_empty ^ color_cond ^ cont ^ color_none) false out expr_true;
                fprintf out "%sval false\n" (offset ^ curr_empty ^ color_cond ^ termin ^ color_none);
                print_expr_indent (offset ^ curr_empty ^ blank ^ color_none) false out expr_false;
            )
            | ESEQ exprs -> (
                fprintf out "%sseq\n" (offset ^ curr_full);
                print_block print_expr_indent (offset ^ blank) out exprs;
            )
    in print_ast_indent "" false out code

let print_declarations (out, color) code =
    let color_none = if color then Pigment.reset else "" in
    let color_fun = if color then Pigment.red_bold else "" in
    let color_var = if color then Pigment.green_bold else "" in
    let rec print_ast_indent offset next out dec_lst =
        let curr_empty = if next then cont else blank in
        let curr_full = if next then bifurc else termin in
        List.iter (function
            | CDECL (_, name, None) -> fprintf out "%svar <%s>\n" (offset ^ curr_full) (color_var ^ name ^ color_none)
            | CDECL (_, name, Some init) -> (
                fprintf out "%svar <%s>\n" (offset ^ curr_full) (color_var ^ name ^ color_none);
                fprintf out "%s(init)\n" (offset ^ blank ^ curr_full);
            )
            | CFUN (_, name, decs, code) -> (
                fprintf out "%sfunc <%s>\n" (offset ^ curr_full) (color_fun ^ name ^ color_none);
                print_ast_indent (offset ^ curr_empty) true out decs;
                fprintf out "%s(body)\n" (offset ^ blank ^ curr_full);
            )
        ) dec_lst
    in print_ast_indent "" false out code

let print_locator out nom fl fc ll lc =
    fprintf out "in file <%s> from %d:%d to %d:%d" nom fl fc ll lc
