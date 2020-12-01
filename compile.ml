open Cparse
open CAST
open Genlab
open Generate
open Printf

let rec zip a b = match (a, b) with
    | (hdl::tll, hdr::tlr) -> (hdl,hdr) :: (zip tll tlr)
    | _ -> []

let rec truncate n lst =
    if lst = [] then []
    else if n = 0 then []
    else (List.hd lst) :: (truncate (n-1) (List.tl lst))

let assoc x ll =
    let rec aux = function
        | [] -> None
        | []::ll -> aux ll
        | ((h,y)::l)::ll when x = h -> Some y
        | (_::l)::ll -> aux (l::ll)
    in aux ll

let rec is_lvalue = function
    | VAR _ -> true
    | OP2 (S_INDEX, lhs, _) -> is_lvalue (snd lhs)
    | OP1 (M_DEREF, _) -> true
    | _ -> false

let generate_asm decl_list =
    let label_cnt = ref 0 in
    let prog = make_prog () in
    let str_count = ref 0 in
    let extract_decl_name = function
        | CDECL (_, name) -> name
        | CFUN (_, name, _, _) -> name
    in
    let whitelist_longret = (
        let rec scan_toplevel = function
            | [] -> ["malloc"; "fopen"; "atol"; "strtol"; "labs"]
            | (CDECL _) :: rest -> scan_toplevel rest
            | (CFUN (_, name, _, _)) :: rest -> name :: (scan_toplevel rest)
        in scan_toplevel decl_list
    ) in
    let rec gen_code (depth, frame, label) code =
        match snd code with
            | CBLOCK (decl_lst, code_lst) -> (
                let frame = (make_scope depth decl_lst) :: frame in
                let depth = depth + List.length decl_lst in
                List.iter (gen_code (depth, frame, label)) code_lst
            )
            | CEXPR expr -> gen_expr (depth, frame, label) expr
            | CIF (cond, do_true, do_false) -> (
                let tagbase = sprintf "%d_cond_" !label_cnt in
                incr label_cnt;
                gen_expr (depth, frame, label) cond;
                decl_asm prog (TST (Regst RAX, Regst RAX)) "apply cond";
                decl_asm prog (JEQ (label, tagbase ^ "false")) "";
                gen_code (depth, frame, label) do_true;
                decl_asm prog (JMP (label, tagbase ^ "done")) "end case true";
                decl_asm prog (TAG (label, tagbase ^ "false")) "begin case false";
                gen_code (depth, frame, label) do_false;
                decl_asm prog (TAG (label, tagbase ^ "done")) "end ternary";
            )
            | CWHILE (cond, code) -> (
                let tagbase = sprintf "%d_loop_" !label_cnt in
                incr label_cnt;
                decl_asm prog (TAG (label, tagbase ^ "enter")) "enter loop";
                gen_expr (depth, frame, label) cond;
                decl_asm prog (CMP (Const 0, Regst RAX)) "";
                decl_asm prog (JEQ (label, tagbase ^ "done")) "";
                gen_code (depth, frame, label) code;
                decl_asm prog (JMP (label, tagbase ^ "enter")) "";
                decl_asm prog (TAG (label, tagbase ^ "done")) "";
            )
            | CRETURN None -> (
                decl_asm prog (MOV (Const 0, Regst RAX)) "return 0";
                decl_asm prog (JMP (label, "return")) " +";
            )
            | CRETURN (Some ret) -> (
                gen_expr (depth, frame, label) ret;
                decl_asm prog (JMP (label, "return")) "return";
            )
    and enter_stackframe () =
        decl_asm prog (PSH (Regst RBP)) "enter stackframe";
        decl_asm prog (MOV (Regst RSP, Regst RBP)) " +";
    and leave_stackframe fname =
        decl_asm prog (XOR (Regst RAX, Regst RAX)) "set to 0";
        decl_asm prog (TAG (fname, "return")) "leave stackframe";
        decl_asm prog (POP (Regst RBP)) " +";
        if fname = "main" then (
            decl_asm prog (MOV (Regst RAX, Regst RDI)) "syscall for exit";
            decl_asm prog (MOV (Const 60, Regst RAX)) " +";
            decl_asm prog SYS " +";
        ) else (
            decl_asm prog RET "";
        )
    and stack_args decs =
        let n = List.length decs in
        let stacked = List.init (max 0 (n-6)) (fun i -> Stack (8*(i+2))) in
        let regged = truncate (min 6 n) [RDI; RSI; RDX; RCX; R08; R09] in
        let names = List.map extract_decl_name decs in
        let regged = List.mapi (fun i (loc, name) ->
            let newloc = Stack (-(i+1)*8) in
            decl_asm prog (MOV (Regst loc, newloc)) (sprintf "store %s" name);
            newloc
        ) (zip regged names) in
        let vars = zip names (regged @ stacked) in
        List.iter (fun (name, loc) -> match loc with
            | Stack k when k > 0 -> decl_asm prog NOP (sprintf "%s is at rRBP+%d" name k)
            | _ -> ()
        ) vars;
        vars
    and make_scope depth decls =
        let n = List.length decls in
        let pos = List.init n (fun i -> Stack (-8*(i+depth))) in
        let names = List.map extract_decl_name decls in
        let vars = zip names pos in
        vars
    and store depth reg =
        decl_asm prog (MOV (Regst reg, Stack (-depth*8))) "store"
    and retrieve depth reg =
        decl_asm prog (MOV (Stack (-depth*8), Regst reg)) "retrieve"
    and gen_decl frame = function
        | CDECL (_, name) -> ()
        | CFUN (_, name, decs, code) -> (
            label_cnt := 0;
            decl_asm prog (FUN name) "toplevel function";
            let nb_args = min 6 (List.length decs) in
            enter_stackframe ();
            let args = stack_args decs in
            gen_code (nb_args+1, args :: frame, name) code;
            leave_stackframe name;
        )
    and gen_expr (depth, frame, label) expr = match snd expr with
        | VAR name -> (match assoc name frame with
            | None -> Error.error (Some (fst expr)) (sprintf "cannot read from undeclared %s.\n" name)
            | Some (Const k) -> decl_asm prog (MOV (Const k, Regst RAX)) (sprintf "const val %s = %d" name k)
            | Some (FnPtr f) -> decl_asm prog (LEA (FnPtr f, Regst RAX)) (sprintf "function pointer %s" f)
            | Some loc -> (
                decl_asm prog (LEA (loc, Regst RDX)) (sprintf "access %s" name);
                decl_asm prog (MOV (Deref RDX, Regst RAX)) (sprintf "read %s" name);
            )
        )
        | CST value -> decl_asm prog (MOV (Const value, Regst RAX)) (sprintf "load val %d" value);
        | STRING str -> (
            let name = sprintf ".LC%d" !str_count in
            incr str_count;
            decl_str prog name str;
            decl_asm prog (LEA (Globl name, Regst RDX)) (sprintf "access %s" name);
            decl_asm prog (MOV (Regst RDX, Regst RAX)) (sprintf "read %s" name);
        )
        | SET_VAR (name, value) -> (
            gen_expr (depth, frame, label) value;
            match assoc name frame with
                | None -> Error.error (Some (fst expr)) (sprintf "cannot assign to undeclared %s.\n" name)
                | Some loc -> (
                    decl_asm prog (LEA (loc, Regst RDX)) (sprintf "access %s" name);
                    decl_asm prog (MOV (Regst RAX, Deref RDX)) (sprintf "write %s" name);
                )
        )
        | SET_ARRAY (arr, idx, value) -> (
            match assoc arr frame with
                | None -> Error.error (Some (fst expr)) (sprintf "cannot assign to undeclared %s.\n" arr)
                | Some loc -> (
                    gen_expr (depth, frame, label) idx;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) value;
                    retrieve (depth) RCX;
                    decl_asm prog (MOV (loc, Regst RDX)) "access array";
                    decl_asm prog (LEA (Index (RDX, RCX), Regst RDX)) " +";
                    decl_asm prog (MOV (Regst RAX, Deref RDX)) " +";
                )
        )
        | SET_DEREF (dest, value) -> (
            gen_expr (depth, frame, label) dest;
            store depth RAX;
            gen_expr (depth+1, frame, label) value;
            retrieve depth RDX;
            decl_asm prog (MOV (Regst RAX, Deref RDX)) "write to deref";
        )
        | OPSET_VAR _ -> failwith "TODO opset var"
        | OPSET_ARRAY _ -> failwith "TODO opset array"
        | OPSET_DEREF _ -> failwith "TODO opset deref"
        | CALL (fname, expr_lst) -> (
            List.iteri (fun i e ->
                gen_expr (depth+i, frame, label) e;
                store (depth+i) RAX;
            ) expr_lst;
            let nb_args = List.length expr_lst in
            let nb_regged = min 6 nb_args in
            let nb_stacked = max 0 (nb_args-6) in
            let reg_dests = truncate nb_regged [RDI; RSI; RDX; RCX; R08; R09] in
            let reg_dests = List.map (fun r -> Regst r) reg_dests in
            let nbvars = depth + nb_args + nb_stacked in
            let offset = nbvars + (nbvars mod 2) in
            let stack_dests = List.init nb_stacked (fun i -> Stack (-(offset-i)*8)) in
            let dests = reg_dests @ stack_dests in
            let locs = List.init nb_args (fun i -> Stack (-(depth+i)*8)) in
            let moves = zip locs dests in
            List.iteri (fun i (loc, dest) ->
                match dest with
                    | Stack k -> (
                        decl_asm prog (MOV (loc, Regst RAX)) (sprintf "%d'th arg" i);
                        decl_asm prog (MOV (Regst RAX, dest)) " +";
                    )
                    | Regst r -> decl_asm prog (MOV (loc, dest)) (sprintf "%d'th arg" i)
                    | _ -> failwith "unreachable @ compile::generate_asm::gen_expr::CALL::iter::_"
            ) moves;
            decl_asm prog (SUB (Const (offset*8), Regst RSP)) (sprintf "%d locals" (depth+nb_args));
            decl_asm prog (MOV (Const nb_stacked, Regst RAX)) (sprintf "varargs: %d on the stack" nb_stacked);
            (match assoc fname frame with
                | None | Some (FnPtr _) -> decl_asm prog (CAL fname) " +"
                | Some loc -> (
                    decl_asm prog (MOV (loc, Regst R10)) "";
                    decl_asm prog (CAL "*%r10") "";
                )
            );
            decl_asm prog (ADD (Const (offset*8), Regst RSP)) " +";
            if not (List.mem fname whitelist_longret)
            then decl_asm prog LTQ "";
        )
        | OP1 (op, expr) -> (
            gen_expr (depth, frame, label) expr;
            match op with
                | M_MINUS -> decl_asm prog (NEG (Regst RAX)) "negative"
                | M_NOT -> decl_asm prog (NOT (Regst RAX)) "bitwise not"
                | M_POST_INC -> if is_lvalue (snd expr)
                    then decl_asm prog (INC (Deref RDX)) "incr (post)"
                    else Error.error (Some (fst expr)) "increment needs an lvalue.\n"
                | M_POST_DEC -> if is_lvalue (snd expr)
                    then decl_asm prog (DEC (Deref RDX)) "decr (post)"
                    else Error.error (Some (fst expr)) "decrement needs an lvalue.\n"
                | M_PRE_INC -> if is_lvalue (snd expr)
                    then (
                        decl_asm prog (INC (Deref RDX)) "incr (pre)";
                        decl_asm prog (INC (Regst RAX)) " +";
                    ) else Error.error (Some (fst expr)) "increment needs an lvalue.\n"
                | M_PRE_DEC -> if is_lvalue (snd expr)
                    then (
                        decl_asm prog (DEC (Deref RDX)) "decr (pre)";
                        decl_asm prog (DEC (Regst RAX)) " +";
                    ) else Error.error (Some (fst expr)) "decrement needs an lvalue.\n"
                | M_DEREF -> (
                    decl_asm prog (MOV (Regst RAX, Regst RDX)) "deref";
                    decl_asm prog (MOV (Deref RAX, Regst RAX)) " +";
                )
                | M_ADDR -> if is_lvalue (snd expr)
                    then decl_asm prog (MOV (Regst RDX, Regst RAX)) "indir"
                    else Error.error (Some (fst expr)) "indirection needs an lvalue.\n"
        )
        | OP2 (op, lhs, rhs) -> (
            match op with
                | S_MUL -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth RCX;
                    decl_asm prog (MUL (Regst RCX)) "mul";
                )
                | S_MOD -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) rhs;
                    decl_asm prog (MOV (Regst RAX, Regst RCX)) "";
                    retrieve depth RAX;
                    decl_asm prog QTO "";
                    decl_asm prog (DIV (Regst RCX)) "div/mod";
                    decl_asm prog (MOV (Regst RDX, Regst RAX)) " + -> mod";
                )
                | S_DIV -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) rhs;
                    decl_asm prog (MOV (Regst RAX, Regst RCX)) "";
                    retrieve depth RAX;
                    decl_asm prog QTO "";
                    decl_asm prog (DIV (Regst RCX)) "div/mod -> div";
                )
                | S_ADD -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth RCX;
                    decl_asm prog (ADD (Regst RCX, Regst RAX)) "add";
                )
                | S_SUB -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth RCX;
                    decl_asm prog (NEG (Regst RAX)) "sub: neg";
                    decl_asm prog (ADD (Regst RCX, Regst RAX)) "    & add";
                )
                | S_INDEX -> (
                    if is_lvalue (snd lhs) then (
                        gen_expr (depth, frame, label) lhs;
                        store depth RAX;
                        gen_expr (depth+1, frame, label) rhs;
                        retrieve depth RCX;
                        decl_asm prog (LEA (Index (RCX, RAX), Regst RDX)) "";
                        decl_asm prog (MOV (Deref RDX, Regst RAX)) "";
                    ) else (
                        Error.error (Some (fst expr)) "index requires an lvalue.\n"
                    )
                )
                | S_SHL -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) rhs;
                    decl_asm prog (MOV (Regst RAX, Regst RCX)) "";
                    retrieve depth RAX;
                    decl_asm prog (SHL (Regst CL, Regst RAX)) "";
                )
                | S_SHR -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) rhs;
                    decl_asm prog (MOV (Regst RAX, Regst RCX)) "";
                    retrieve depth RAX;
                    decl_asm prog (SHR (Regst CL, Regst RAX)) "";
                )
                | S_AND -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth RCX;
                    decl_asm prog (AND (Regst RCX, Regst RAX)) "and";
                )
                | S_OR -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth RCX;
                    decl_asm prog (IOR (Regst RCX, Regst RAX)) "incl. or";
                )
                | S_XOR -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth RCX;
                    decl_asm prog (XOR (Regst RCX, Regst RAX)) "excl. or";
                )
        )
        | CMP (op, lhs, rhs) -> (
            gen_expr (depth, frame, label) lhs;
            store depth RAX;
            gen_expr (depth+1, frame, label) rhs;
            retrieve depth RCX;
            decl_asm prog (CMP (Regst RAX, Regst RCX)) "compare";
            let tagbase = sprintf "%d_cmp_" !label_cnt in
            incr label_cnt;
            match op with
                | C_LT -> (
                    decl_asm prog (JLT (label, tagbase ^ "lt")) "case <";
                    decl_asm prog (MOV (Const 0, Regst RAX)) "";
                    decl_asm prog (JMP (label, tagbase ^ "done")) " +";
                    decl_asm prog (TAG (label, tagbase ^ "lt")) " +";
                    decl_asm prog (MOV (Const 1, Regst RAX)) " +";
                    decl_asm prog (TAG (label, tagbase ^ "done")) " +";
                )
                | C_LE -> (
                    decl_asm prog (JLE (label, tagbase ^ "le")) "case <=";
                    decl_asm prog (MOV (Const 0, Regst RAX)) " +";
                    decl_asm prog (JMP (label, tagbase ^ "done")) " +";
                    decl_asm prog (TAG (label, tagbase ^ "le")) " +";
                    decl_asm prog (MOV (Const 1, Regst RAX)) " +";
                    decl_asm prog (TAG (label, tagbase ^ "done")) " +";
                )
                | C_EQ -> (
                    decl_asm prog (JEQ (label, tagbase ^ "eq")) "case ==";
                    decl_asm prog (MOV (Const 0, Regst RAX)) " +";
                    decl_asm prog (JMP (label, tagbase ^ "done")) " +";
                    decl_asm prog (TAG (label, tagbase ^ "eq")) " +";
                    decl_asm prog (MOV (Const 1, Regst RAX)) " +";
                    decl_asm prog (TAG (label, tagbase ^ "done")) " +";
                )
                | C_GT -> (
                    decl_asm prog (JLE (label, tagbase ^ "le")) "case ! >";
                    decl_asm prog (MOV (Const 1, Regst RAX)) "";
                    decl_asm prog (JMP (label, tagbase ^ "done")) " +";
                    decl_asm prog (TAG (label, tagbase ^ "le")) " +";
                    decl_asm prog (MOV (Const 0, Regst RAX)) " +";
                    decl_asm prog (TAG (label, tagbase ^ "done")) " +";
                )
                | C_GE -> (
                    decl_asm prog (JLT (label, tagbase ^ "lt")) "case ! >=";
                    decl_asm prog (MOV (Const 1, Regst RAX)) "";
                    decl_asm prog (JMP (label, tagbase ^ "done")) " +";
                    decl_asm prog (TAG (label, tagbase ^ "lt")) " +";
                    decl_asm prog (MOV (Const 0, Regst RAX)) " +";
                    decl_asm prog (TAG (label, tagbase ^ "done")) " +";
                )
        )
        | EIF (cond, expr_true, expr_false) -> (
            let tagbase = sprintf "%d_tern_" !label_cnt in
            incr label_cnt;
            gen_expr (depth, frame, label) cond;
            decl_asm prog (TST (Regst RAX, Regst RAX)) "apply ternary";
            decl_asm prog (JEQ (label, tagbase ^ "false")) "";
            gen_expr (depth, frame, label) expr_true;
            decl_asm prog (JMP (label, tagbase ^ "done")) "end case true";
            decl_asm prog (TAG (label, tagbase ^ "false")) "begin case false";
            gen_expr (depth, frame, label) expr_false;
            decl_asm prog (TAG (label, tagbase ^ "done")) "end ternary";
        )
        | ESEQ exprs -> List.iter (gen_expr (depth, frame, label)) exprs
    in
    let rec get_global_vars = function
        | [] -> []
        | (CFUN (_, name, _, _)) :: tl -> (name, FnPtr name) :: (get_global_vars tl)
        | (CDECL (_, name)) :: tl -> (
            decl_int prog name;
            (name, (Globl name)) :: (get_global_vars tl)
        )
    in
    let universal = [
        ("stdin", Globl "stdin"); ("stdout", Globl "stdout"); ("stderr", Globl "stderr");
        ("SIZE", Const 8); ("EOF", Const (-1)); ("NULL", Const 0);
        ("true", Const 1); ("false", Const 0);
        ("SIGABRT", Const 6); ("SIGFPE", Const 8); ("SIGILL", Const 4);
        ("SIGINT", Const 2); ("SIGSEGV", Const 11); ("SIGTERM", Const 15);
        ("RAND_MAX", Const 2147483647);
    ] in
    let global = get_global_vars decl_list in
    List.iter (gen_decl (global::[universal])) decl_list;
    prog


let compile (out, color) decl_list =
    let instructions = generate_asm decl_list in
    if !Error.error_count = 0 then
        generate (out, color) instructions
    else (
        Error.flush_error ();
        printf "%d errors were found, no assembler generated.\n" !Error.error_count;
        flush stdout;
        exit 100
    )
