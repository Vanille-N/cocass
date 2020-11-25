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
    and enter_stackframe n =
        fprintf out "    push %%rbp\n";
        fprintf out "    mov %%rsp, %%rbp\n";
        fprintf out "    sub $%d, %%rsp\n" (8*(n+1));
    and leave_stackframe n =
        fprintf out "    add $%d, %%rsp\n" (8*(n+1));
        fprintf out "    pop %%rbp\n";
        fprintf out "    ret\n"
    and read_args decs = []
    and make_scope depth decls =
        let n = List.length decls in
        let pos = List.init n (fun i -> sprintf "-%d(%%rbp)" (8*(i+1+depth))) in
        let names = List.map extract_decl_name decls in
        let vars = zip names pos in
        List.iter (fun (name, pos) -> printf " %s is at %s\n" name pos) vars;
        vars
    and calc_stackframe_depth depth code = match snd code with
        | CBLOCK (decl_lst, code_lst) -> (
            let n = List.length decl_lst in
            let depth_block = ref 0 in
            let frame_block = ref [] in
            List.iteri (fun i block ->
                let d = calc_stackframe_depth (depth + n) block in
                depth_block := max !depth_block d;
            ) code_lst;
            !depth_block
        )
        | CIF (_, code_true, code_false) -> (
            let depth_t = calc_stackframe_depth depth code_true in
            let depth_f = calc_stackframe_depth depth code_false in
            max depth_t depth_f
        )
        | CWHILE (cond, code) -> failwith "TODO stackframe while"
        | _ -> depth
    and gen_decl = function
        | CDECL (_, name) -> ()
        | CFUN (_, name, decs, code) -> (
            fprintf out "fn_%s:\n" name;
            let args = read_args decs in
            let n = calc_stackframe_depth 0 code in
            enter_stackframe n;
            gen_code (0, args) code;
            leave_stackframe n;
        )
    and gen_expr (depth, frame) expr = match snd expr with
        | VAR name -> fprintf out "    mov %s, %%rax\n" (List.assoc name frame)
        | CST value -> fprintf out "    mov $%d, %%rax\n" value
        | STRING str -> failwith "TODO string"
        | SET_VAR (name, expr) -> (
            gen_expr (depth, frame) expr;
            printf "looking for %s\n" name;
            fprintf out "    mov %%rax, %s\n" (List.assoc name frame)
        )
        | SET_ARRAY (name, index, value) -> failwith "TODO set array"
        | CALL (fname, expr_lst) -> failwith "TODO call"
        | OP1 (op, expr) -> (
            gen_expr (depth, frame) expr;
            match op with
                | M_MINUS -> failwith "TODO minus"
                | M_NOT -> failwith "TODO not"
                | M_POST_INC -> failwith "TODO post inc"
                | M_POST_DEC -> failwith "TODO post dec"
                | M_PRE_INC -> failwith "TODO pre inc"
                | M_PRE_DEC -> failwith "TODO pre dec"
        )
        | OP2 (op, lhs, rhs) -> failwith "TODO op2"
        | CMP (op, lhs, rhs) -> failwith "TODO cmp"
        | EIF (cond, expr_true, expr_false) -> failwith "TODO eif"
        | ESEQ exprs -> List.iter (gen_expr (depth, frame)) exprs
    in
    List.iter gen_decl decl_list


let compile out decl_list =
    if verify_scope decl_list then (
        global_decl out decl_list;
        generate_asm out decl_list;
    )
