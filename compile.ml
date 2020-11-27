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

let assoc x ll =
    let rec aux = function
        | [] -> raise Not_found
        | []::ll -> aux ll
        | ((h,y)::l)::ll when x = h -> y
        | (_::l)::ll -> aux (l::ll)
    in aux ll

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
    let extract_decl_name = function
        | CDECL (_, name) -> name
        | CFUN (_, name, _, _) -> name
    in
    let rec gen_code (depth, frame) code = match snd code with
        | CBLOCK (decl_lst, code_lst) -> (
            List.iter (gen_code (depth + List.length decl_lst, (make_scope depth decl_lst) :: frame)) code_lst
        )
        | CEXPR expr -> gen_expr (depth, frame) expr
        | CIF (expr, do_true, do_false) -> failwith "TODO if"
        | CWHILE (cond, code) -> failwith "TODO while"
        | CRETURN None -> (
            fprintf out "    mov $0, %%rax\n";
            fprintf out "    jmp .leave\n";
        )
        | CRETURN (Some ret) -> (
            gen_expr (depth, frame) ret;
            fprintf out "    jmp .leave\n";
        )
    and enter_stackframe n =
        fprintf out "    push %%rbp        # enter stackframe\n";
        fprintf out "    mov %%rsp, %%rbp\n";
    and leave_stackframe n =
        fprintf out "  .leave:             # leave stackframe\n";
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
    and store depth reg =
        fprintf out "    mov %s, -%d(%%rbp)\n" reg ((depth+1)*8)
    and retrieve depth reg =
        fprintf out "    mov -%d(%%rbp), %s\n" ((depth+1)*8) reg
    and gen_decl global = function
        | CDECL (_, name) -> ()
        | CFUN (_, name, decs, code) -> (
            fprintf out "fn_%s:\n" name;
            let args = read_args decs in
            let n = calc_stackframe_depth 0 code in
            enter_stackframe n;
            gen_code (0, args :: [global]) code;
            leave_stackframe n;
        )
    and gen_expr (depth, frame) expr = match snd expr with
        | VAR name -> (
            let loc = assoc name frame in
            fprintf out "    lea %s, %%rbx    # access %s\n" loc name;
            fprintf out "    mov (%%rbx), %%rax    # read from %s\n" name;
        )
        | CST value -> fprintf out "    mov $%d, %%rax     # load value %d\n" value value
        | STRING str -> failwith "TODO string"
        | SET_VAR (name, expr) -> (
            gen_expr (depth, frame) expr;
            let loc = assoc name frame in
            fprintf out "    lea %s, %%rbx    # acccess %s\n" loc name;
            fprintf out "    mov %%rax, (%%rbx)    # write to %s\n" name;
        )
        | SET_ARRAY (name, index, value) -> failwith "TODO set array"
        | CALL (fname, expr_lst) -> failwith "TODO call"
        | OP1 (op, expr) -> (
            match op with
                | M_MINUS -> (
                    gen_expr (depth, frame) expr;
                    fprintf out "    neg %%rax\n";
                )
                | M_NOT -> (
                    gen_expr (depth, frame) expr;
                    fprintf out "    not %%rax\n";
                )
                | M_POST_INC -> (
                    gen_expr (depth, frame) expr;
                    fprintf out "    incq (%%rbx)\n";
                )
                | M_POST_DEC -> (
                    gen_expr (depth, frame) expr;
                    fprintf out "    decq (%%rbx)\n";
                )
                | M_PRE_INC -> (
                    gen_expr (depth, frame) expr;
                    fprintf out "    incq (%%rbx)\n";
                    fprintf out "    inc %%rax\n";
                )
                | M_PRE_DEC -> (
                    gen_expr (depth, frame) expr;
                    fprintf out "    decq (%%rbx)\n";
                    fprintf out "    dec %%rax\n";
                )
        )
        | OP2 (op, lhs, rhs) -> (
            match op with
                | S_MUL -> (
                    gen_expr (depth, frame) lhs;
                    store depth "%rax";
                    gen_expr (depth+1, frame) rhs;
                    retrieve depth "%rcx";
                    fprintf out "    mul %%rcx\n";
                )
                | S_MOD -> (
                    gen_expr (depth, frame) lhs;
                    store depth "%rax";
                    gen_expr (depth+1, frame) rhs;
                    fprintf out "    mov %%rax, %%rcx\n";
                    retrieve depth "%rax";
                    fprintf out "    cqto\n";
                    fprintf out "    idiv %%rcx\n";
                    fprintf out "    mov %%rdx, %%rax\n";
                )
                | S_DIV -> (
                    gen_expr (depth, frame) lhs;
                    store depth "%rax";
                    gen_expr (depth+1, frame) rhs;
                    fprintf out "    mov %%rax, %%rcx\n";
                    retrieve depth "%rax";
                    fprintf out "    cqto\n";
                    fprintf out "    idiv %%rcx\n";
                )
                | S_ADD -> (
                    gen_expr (depth, frame) lhs;
                    store depth "%rax";
                    gen_expr (depth+1, frame) rhs;
                    retrieve depth "%rcx";
                    fprintf out "    add %%rcx, %%rax\n";
                )
                | S_SUB -> (
                    gen_expr (depth, frame) lhs;
                    store depth "%rax";
                    gen_expr (depth+1, frame) rhs;
                    retrieve depth "%rcx";
                    fprintf out "    neg %%rax\n";
                    fprintf out "    add %%rcx, %%rax\n";
                )
                | S_INDEX -> failwith "TODO index"
        )
        | CMP (op, lhs, rhs) -> failwith "TODO cmp"
        | EIF (cond, expr_true, expr_false) -> failwith "TODO eif"
        | ESEQ exprs -> List.iter (gen_expr (depth, frame)) exprs
    in
    let rec get_global_vars = function
        | [] -> []
        | (CFUN _) :: tl -> get_global_vars tl
        | (CDECL (_, name)) :: tl -> (
            fprintf out "glob_%s: .long 0\n" name;
            (name, ("glob_" ^ name ^ "(%rip)")) :: (get_global_vars tl)
        )
    in
    fprintf out "    .data\n";
    fprintf out "    .align 8\n";
    let global = get_global_vars decl_list in
    fprintf out "\n";
    fprintf out "    .global main\n";
    fprintf out "    .text\n";
    fprintf out "main:\n";
    fprintf out "    call fn_main\n";
    fprintf out "    mov %%rax, %%rdi     # return value\n";
    fprintf out "    mov $60, %%rax      # syscall for return\n";
    fprintf out "    syscall\n";
    List.iter (gen_decl global) decl_list


let compile out decl_list =
    if verify_scope decl_list then (
        global_decl out decl_list;
        generate_asm out decl_list;
    )
