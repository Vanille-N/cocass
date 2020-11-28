open Cparse
open CAST
open Genlab
open Printf

let rec all f = function
    | [] -> true
    | hd::tl -> (f hd) && (all f tl)

let rec zip a b = match (a, b) with
    | (hdl::tll, hdr::tlr) -> (hdl,hdr) :: (zip tll tlr)
    | _ -> []

let rec truncate n lst =
    if lst = [] then []
    else if n = 0 then []
    else (List.hd lst) :: (truncate (n-1) (List.tl lst))

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
    let rec gen_code (depth, frame, label) code =
        match snd code with
            | CBLOCK (decl_lst, code_lst) -> (
                let frame = (make_scope depth decl_lst) :: frame in
                let depth = depth + List.length decl_lst in
                List.iter (gen_code (depth, frame, label)) code_lst
            )
            | CEXPR expr -> gen_expr (depth, frame, label) expr
            | CIF (expr, do_true, do_false) -> failwith "TODO if"
            | CWHILE (cond, code) -> failwith "TODO while"
            | CRETURN None -> (
                fprintf out "    mov $0, %%rax\n";
                fprintf out "    jmp %s.leave\n" label;
            )
            | CRETURN (Some ret) -> (
                gen_expr (depth, frame, label) ret;
                fprintf out "    jmp %s.leave\n" label;
            )
    and enter_stackframe () =
        fprintf out "    push %%rbp        # enter stackframe\n";
        fprintf out "    mov %%rsp, %%rbp\n"
    and leave_stackframe fname =
        fprintf out "    mov $0, %%rax\n";
        fprintf out "  %s.leave:             # leave stackframe\n" fname;
        fprintf out "    pop %%rbp\n";
        if fname = "main" then (
            fprintf out "    mov %%rax, %%rdi     # return value\n";
            fprintf out "    mov $60, %%rax      # syscall for return\n";
            fprintf out "    syscall\n\n";
        ) else (
            fprintf out "    ret\n\n";
        )
    and stack_args decs =
        let n = List.length decs in
        let stacked = List.init (max 0 (n-6)) (fun i -> sprintf "%d(%%rbp)" (8*(i+2))) in
        let regged = truncate (min 6 n) ["%rdi"; "%rsi"; "%rdx"; "%rcx"; "%r8"; "%r9"] in
        let regged = List.mapi (fun i loc ->
            let newloc = sprintf "-%d(%%rbp)" ((i+1)*8) in
            fprintf out "    mov %s, %s\n" loc newloc;
            newloc
        ) regged in
        let names = List.map extract_decl_name decs in
        zip names (regged @ stacked)
    and make_scope depth decls =
        let n = List.length decls in
        let pos = List.init n (fun i -> sprintf "-%d(%%rbp)" (8*(i+1+depth))) in
        let names = List.map extract_decl_name decls in
        let vars = zip names pos in
        List.iter (fun (name, pos) -> printf " %s is at %s\n" name pos) vars;
        vars
    and store depth reg =
        fprintf out "    mov %s, -%d(%%rbp)\n" reg ((depth+1)*8)
    and retrieve depth reg =
        fprintf out "    mov -%d(%%rbp), %s\n" ((depth+1)*8) reg
    and gen_decl global = function
        | CDECL (_, name) -> ()
        | CFUN (_, name, decs, code) -> (
            fprintf out "%s:\n" name;
            let nb_args = min 6 (List.length decs) in
            enter_stackframe ();
            let args = stack_args decs in
            gen_code (nb_args, args :: [global], name) code;
            leave_stackframe name;
        )
    and gen_expr (depth, frame, label) expr = match snd expr with
        | VAR name -> (
            let loc = assoc name frame in
            fprintf out "    lea %s, %%rbx    # access %s\n" loc name;
            fprintf out "    mov (%%rbx), %%rax    # read from %s\n" name;
        )
        | CST value -> fprintf out "    mov $%d, %%rax     # load value %d\n" value value
        | STRING str -> failwith "TODO string"
        | SET_VAR (name, expr) -> (
            gen_expr (depth, frame, label) expr;
            let loc = assoc name frame in
            printf "found %s at %s\n" name loc; flush stdout;
            fprintf out "    lea %s, %%rbx    # acccess %s\n" loc name;
            fprintf out "    mov %%rax, (%%rbx)    # write to %s\n" name;
        )
        | SET_ARRAY (name, index, value) -> failwith "TODO set array"
        | CALL (fname, expr_lst) -> (
            List.iteri (fun i e ->
                gen_expr (depth+i, frame, label) e;
                store (depth+i) "%rax";
            ) expr_lst;
            let nb_args = List.length expr_lst in
            let nb_regged = min 6 nb_args in
            let nb_stacked = max 0 (nb_args-6) in
            let reg_dests = truncate nb_regged ["%rdi"; "%rsi"; "%rdx"; "%rcx"; "%r8"; "%r9"] in
            let stack_dests = List.init nb_stacked (fun i -> sprintf "-%d(%%rbp)" ((depth+nb_args+1+i)*8)) in
            let dests = reg_dests @ stack_dests in
            let locs = List.init nb_args (fun i -> sprintf "-%d(%%rbp)" ((depth+1+i)*8)) in
            let moves = zip locs dests in
            List.iter (fun (loc, dest) ->
                fprintf out "    mov %s, %%rax\n" loc;
                fprintf out "    mov %%rax, %s\n" dest;
            ) moves;
            fprintf out "    sub $%d, %%rsp\n" ((depth+nb_args+1)*8);
            fprintf out "    call %s\n" fname;
            fprintf out "    add $%d, %%rsp\n" ((depth+nb_args+1)*8);
        )
        | OP1 (op, expr) -> (
            gen_expr (depth, frame, label) expr;
            match op with
                | M_MINUS -> fprintf out "    neg %%rax\n"
                | M_NOT -> fprintf out "    not %%rax\n"
                | M_POST_INC -> fprintf out "    incq (%%rbx)\n"
                | M_POST_DEC -> fprintf out "    decq (%%rbx)\n"
                | M_PRE_INC -> (
                    fprintf out "    incq (%%rbx)\n";
                    fprintf out "    inc %%rax\n";
                )
                | M_PRE_DEC -> (
                    fprintf out "    decq (%%rbx)\n";
                    fprintf out "    dec %%rax\n";
                )
        )
        | OP2 (op, lhs, rhs) -> (
            match op with
                | S_MUL -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth "%rax";
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth "%rcx";
                    fprintf out "    mul %%rcx\n";
                )
                | S_MOD -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth "%rax";
                    gen_expr (depth+1, frame, label) rhs;
                    fprintf out "    mov %%rax, %%rcx\n";
                    retrieve depth "%rax";
                    fprintf out "    cqto\n";
                    fprintf out "    idiv %%rcx\n";
                    fprintf out "    mov %%rdx, %%rax\n";
                )
                | S_DIV -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth "%rax";
                    gen_expr (depth+1, frame, label) rhs;
                    fprintf out "    mov %%rax, %%rcx\n";
                    retrieve depth "%rax";
                    fprintf out "    cqto\n";
                    fprintf out "    idiv %%rcx\n";
                )
                | S_ADD -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth "%rax";
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth "%rcx";
                    fprintf out "    add %%rcx, %%rax\n";
                )
                | S_SUB -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth "%rax";
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth "%rcx";
                    fprintf out "    neg %%rax\n";
                    fprintf out "    add %%rcx, %%rax\n";
                )
                | S_INDEX -> failwith "TODO index"
        )
        | CMP (op, lhs, rhs) -> failwith "TODO cmp"
        | EIF (cond, expr_true, expr_false) -> failwith "TODO eif"
        | ESEQ exprs -> List.iter (gen_expr (depth, frame, label)) exprs
    in
    let rec get_global_vars = function
        | [] -> []
        | (CFUN _) :: tl -> get_global_vars tl
        | (CDECL (_, name)) :: tl -> (
            fprintf out "%s: .long 0\n" name;
            (name, (name ^ "(%rip)")) :: (get_global_vars tl)
        )
    in
    fprintf out "    .data\n";
    fprintf out "    .align 8\n";
    let global = get_global_vars decl_list in
    fprintf out "\n";
    fprintf out "    .global main\n";
    fprintf out "    .text\n";
    List.iter (gen_decl global) decl_list


let compile out decl_list =
    if verify_scope decl_list then (
        global_decl out decl_list;
        generate_asm out decl_list;
    )
