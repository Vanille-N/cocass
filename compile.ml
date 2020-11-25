open Cparse
open CAST
open Genlab
open Printf

let rec all f = function
    | [] -> true
    | hd::tl -> (f hd) && (all f tl)

let rec zip a b = match (a, b) with
    | ([], []) -> []
    | (hdl::tll, hdr::tlr) -> (hdl,hdr) :: (zip tll tlr)
    | _ -> failwith "cannot zip different lengths"

let verify_scope decl_list =
    let rec verify_expr declared expr = match snd expr with
        | VAR name -> List.mem name declared
        | CST value -> true
        | STRING str -> true
        | SET_VAR (name, expr) -> verify_expr declared expr
        | SET_ARRAY (name, index, value) -> all (verify_expr declared) [index; value]
        | CALL (fname, expr_lst) -> all (verify_expr declared) expr_lst
        | OP1 (op, expr) -> verify_expr declared expr
        | OP2 (op, lhs, rhs) -> all (verify_expr declared) [lhs; rhs]
        | CMP (op, lhs, rhs) -> all (verify_expr declared) [lhs; rhs]
        | EIF (cond, expr_true, expr_false) -> all (verify_expr declared) [cond; expr_true; expr_false]
        | ESEQ exprs -> verify_block declared exprs
    and verify_block declared code = true
    in true

let global_decl out decl_list = ()

let generate_asm out decl_list =
    fprintf out ".global main
.text
main:
    call fn_main
    mov %%rax, %%rdi # return value
    mov $60, %%rax # syscall for return
    syscall
";
    let extract_decl_name = function
        | CDECL (_, name) -> name
        | CFUN (_, name, _, _) -> name
    in
    let rec gen_code (depth, frame) code = match snd code with
        | CBLOCK (decl_lst, code_lst) -> (
            List.iter (gen_code (depth + List.length decl_lst, (make_scope depth decl_lst) @ frame)) code_lst
        )
        | CEXPR expr -> gen_expr (depth, frame) expr
        | CIF (expr, do_true, do_false) -> failwith "TODO if"
        | CWHILE (cond, code) -> failwith "TODO while"
        | CRETURN None -> fprintf out "    mov $0, %%rax\n"
        | CRETURN (Some ret) -> gen_expr (depth, frame) ret
