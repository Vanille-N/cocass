open CAST
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
    | S_SHL -> "SHL"
    | S_SHR -> "SHR"

let cmp_op_repr = function
    | C_LT -> "LT"
    | C_LE -> "LE"
    | C_EQ -> "EQ"
    | C_GT -> "GT"
    | C_GE -> "GE"

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

let print_ast_close_to_C out dec_list =
  let rec string_of_dec l n = match l with
    |[] -> ""
    |h::suite ->
      let l = string_of_dec suite n in
      begin
        match h with
        |CDECL(_,var) ->
          String.concat "" [String.make n ' ';"CDECL{";"VAR{";var;"}";"}\n";l]
        |CFUN(_,f,args,(_,code)) ->
          String.concat "" [String.make n ' ';
                            "CFUN{\n";String.make (n+2) ' ';f;
                            "{\n";string_of_dec args (n+4);String.make (n+2) ' ';"}\n";
                            string_of_code code (n+2);String.make n ' ';"}\n";l]
      end
  and string_of_code c n = match c with
    |CBLOCK(decs,code) ->
      String.concat "" [String.make n ' ';
                        "CBLOCK{\n";string_of_dec decs (n+2);
                        string_of_codelist code (n+2);String.make n ' ';"}\n"]
    |CEXPR((_,e)) ->
      String.concat "" [String.make n ' ';"CEXPR{";string_of_expr e 0;"}\n"]
    |CIF((_,e),(_,c1),(_,c2)) ->
      String.concat "" [String.make n ' ';
                        "CIF{\n";
                        string_of_expr e  0;"\n";
                        string_of_code c1 0;"\n";
                        string_of_code c2 0;"\n";
                        String.make n ' ';"}\n"]
    |CWHILE((_,e),(_,c)) ->
      String.concat "" [String.make n ' ';
                        "CWHILE{\n";string_of_expr e (n+2);string_of_code c (n+2);
                        String.make n ' ';"}\n"]
    |CRETURN(Some(_,e)) ->
      String.concat "" [String.make n ' ';"CRETURN{";string_of_expr e 0;"}\n"]
    |CRETURN(None) ->
      String.concat "" [String.make n ' ';"CRETURN{ }\n"]
  and string_of_expr e n = match e with
    |VAR(s) ->
      String.concat "" ["VAR{";s;"}"]
    |CST(p) ->
      String.concat "" ["CST{";string_of_int p;"}"]
    |STRING(s) ->
      String.concat "" ["STRING{";s;"}"]
    |SET_VAR(s,(_,e1)) ->
      String.concat "" ["SET_VAR{";s;", ";string_of_expr e1 0;"}"]
    |SET_ARRAY(s,(_,e1),(_,e2)) ->
      String.concat "" ["SET_ARRAY{";s;", ";
                        string_of_expr e1 0;", ";
                        string_of_expr e2 0;"}"]
    |CALL(s,l) ->
      let list=string_of_exprlist l 0 in
      String.concat "" ["CALL{";s;", ";list;"}"]
    |OP1(mop,(_,e1)) ->
      String.concat "" ["OP1{";string_of_monop mop;"{";string_of_expr e1 0;"}} "]
    |OP2(bop,(_,e1),(_,e2)) ->
      String.concat "" ["OP2{";string_of_binop bop;"{";string_of_expr e1 0;", ";string_of_expr e2 0;"}"]
    |CMP(cop,(_,e1),(_,e2)) ->
      String.concat "" [String.make n ' ';"CMP{";string_of_cmpop cop;"{"; string_of_expr e1 0;", ";string_of_expr e2 0;"}}\n"]
    |EIF((_,e1),(_,e2),(_,e3)) ->
      String.concat "" [String.make n ' ';
                        "EIF{\n";
                        String.make (n+2) ' ';string_of_expr e1 0;"\n";
                        String.make (n+2) ' ';string_of_expr e2 0;"\n";
                        String.make (n+2) ' ';string_of_expr e3 0;"\n";
                        String.make n ' ';"}\n"]
    |ESEQ(l) -> let string=string_of_exprlist l 0 in
                String.concat "" [String.make n ' ';
                                  "ESEQ{";string;"}\n"]
  and string_of_exprlist l n = match l with
    |[] -> ""
    |(_,exp)::r -> String.concat ", " [string_of_expr exp n;string_of_exprlist r n]
  and string_of_codelist l n = match l with
    |[] -> ""
    |(_,code)::r ->
      String.concat "" [string_of_code code n;string_of_codelist r n]
  and string_of_monop = mon_op_repr
  and string_of_binop = bin_op_repr
  and string_of_cmpop = cmp_op_repr

  in
  Format.fprintf out "%s" (string_of_dec dec_list 0);;
