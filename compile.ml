open Cparse
open CAST
open Genlab
open Generate
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
        | [] -> None
        | []::ll -> aux ll
        | ((h,y)::l)::ll when x = h -> Some y
        | (_::l)::ll -> aux (l::ll)
    in aux ll

let unwrap = function
    | Some x -> x
    | None -> raise Not_found

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
    let label_cnt = ref 0 in
    let prog = make_prog () in
    let str_count = ref 0 in
    let extract_decl_name = function
        | CDECL (_, name) -> name
        | CFUN (_, name, _, _) -> name
    in
    let whitelist_longret = (
        let rec scan_toplevel = function
            | [] -> ["malloc"; "fopen"]
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
                decl_asm prog (CMP (Const 0, Reg AX)) "apply cond";
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
                decl_asm prog (CMP (Const 0, Reg AX)) "";
                decl_asm prog (JEQ (label, tagbase ^ "done")) "";
                gen_code (depth, frame, label) code;
                decl_asm prog (JMP (label, tagbase ^ "enter")) "";
                decl_asm prog (TAG (label, tagbase ^ "done")) "";
            )
            | CRETURN None -> (
                decl_asm prog (MOV (Const 0, Reg AX)) "return 0";
                decl_asm prog (JMP (label, "return")) " +";
            )
            | CRETURN (Some ret) -> (
                gen_expr (depth, frame, label) ret;
                decl_asm prog (JMP (label, "return")) "return";
            )
    and enter_stackframe () =
        decl_asm prog (PUSH (Reg BP)) "enter stackframe";
        decl_asm prog (MOV (Reg SP, Reg BP)) " +";
    and leave_stackframe fname =
        decl_asm prog (MOV (Const 0, Reg AX)) "";
        decl_asm prog (TAG (fname, "return")) "leave stackframe";
        decl_asm prog (POP (Reg BP)) " +";
        if fname = "main" then (
            decl_asm prog (MOV (Reg AX, Reg DI)) "syscall for exit";
            decl_asm prog (MOV (Const 60, Reg AX)) " +";
            decl_asm prog SYS " +";
        ) else (
            decl_asm prog RET "";
        )
    and stack_args decs =
        let n = List.length decs in
        let stacked = List.init (max 0 (n-6)) (fun i -> Stack (8*(i+2))) in
        let regged = truncate (min 6 n) [DI; SI; DX; CX; R8; R9] in
        let names = List.map extract_decl_name decs in
        let regged = List.mapi (fun i (loc, name) ->
            let newloc = Stack (-(i+1)*8) in
            decl_asm prog (MOV (Reg loc, newloc)) (sprintf "store %s" name);
            newloc
        ) (zip regged names) in
        let vars = zip names (regged @ stacked) in
        List.iter (fun (name, loc) -> match loc with
            | Stack k when k > 0 -> decl_asm prog NOP (sprintf "%s is at rbp+%d" name k)
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
        decl_asm prog (MOV (Reg reg, Stack (-depth*8))) "store"
    and retrieve depth reg =
        decl_asm prog (MOV (Stack (-depth*8), Reg reg)) "retrieve"
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
        | VAR name -> (
            let loc = unwrap (assoc name frame) in
            match loc with
                | Const k -> decl_asm prog (MOV (loc, Reg AX)) (sprintf "const val %s = %d" name k);
                | loc -> (
                    decl_asm prog (LEA (loc, Reg DX)) (sprintf "access %s" name);
                    decl_asm prog (MOV (Deref DX, Reg AX)) (sprintf "read %s" name);
                )
        )
        | CST value -> decl_asm prog (MOV (Const value, Reg AX)) (sprintf "load val %d" value);
        | STRING str -> (
            let name = sprintf ".LC%d" !str_count in
            incr str_count;
            decl_str prog name str;
            decl_asm prog (LEA (Glob name, Reg DX)) (sprintf "access %s" name);
            decl_asm prog (MOV (Reg DX, Reg AX)) (sprintf "read %s" name);
        )
        | SET_VAR (name, expr) -> (
            gen_expr (depth, frame, label) expr;
            let loc = unwrap (assoc name frame) in
            decl_asm prog (LEA (loc, Reg DX)) (sprintf "access %s" name);
            decl_asm prog (MOV (Reg AX, Deref DX)) (sprintf "write %s" name);
        )
        | SET_ARRAY (arr, idx, value) -> (
            let loc = unwrap (assoc arr frame) in
            gen_expr (depth, frame, label) idx;
            store depth AX;
            gen_expr (depth+1, frame, label) value;
            retrieve (depth) CX;
            decl_asm prog (MOV (loc, Reg DX)) "access array";
            decl_asm prog (LEA (Index (DX, CX), Reg DX)) " +";
            decl_asm prog (MOV (Reg AX, Deref DX)) " +";
        )
        | CALL (fname, expr_lst) -> (
            List.iteri (fun i e ->
                gen_expr (depth+i, frame, label) e;
                store (depth+i) AX;
            ) expr_lst;
            let nb_args = List.length expr_lst in
            let nb_regged = min 6 nb_args in
            let nb_stacked = max 0 (nb_args-6) in
            let reg_dests = truncate nb_regged [DI; SI; DX; CX; R8; R9] in
            let reg_dests = List.map (fun r -> Reg r) reg_dests in
            let stack_dests = List.init nb_stacked (fun i -> Stack (-(depth+nb_args+nb_stacked-i)*8)) in
            let dests = reg_dests @ stack_dests in
            let locs = List.init nb_args (fun i -> Stack (-(depth+i)*8)) in
            let moves = zip locs dests in
            List.iteri (fun i (loc, dest) ->
                match dest with
                    | Stack k -> (
                        decl_asm prog (MOV (loc, Reg AX)) (sprintf "%d'th arg" i);
                        decl_asm prog (MOV (Reg AX, dest)) " +";
                    )
                    | Reg r -> decl_asm prog (MOV (loc, dest)) (sprintf "%d'th arg" i)
                    | _ -> failwith "unreachable @ compile::generate_asm::gen_expr::CALL::iter::_"
            ) moves;
            decl_asm prog (SUB (Const ((depth+nb_args+nb_stacked)*8), Reg SP)) (sprintf "%d locals" (depth+nb_args));
            decl_asm prog (MOV (Const nb_stacked, Reg AX)) (sprintf "varargs: %d on the stack" nb_stacked);
            decl_asm prog (CALL fname) " +";
            decl_asm prog (ADD (Const ((depth+nb_args+nb_stacked)*8), Reg SP)) " +";
            if not (List.mem fname whitelist_longret)
            then decl_asm prog CLTQ "";
        )
        | OP1 (op, expr) -> (
            gen_expr (depth, frame, label) expr;
            match op with
                | M_MINUS -> decl_asm prog (NEG (Reg AX)) "negative";
                | M_NOT -> decl_asm prog (NOT (Reg AX)) "bitwise not";
                | M_POST_INC -> decl_asm prog (INC (Deref DX)) "incr (post)";
                | M_POST_DEC -> decl_asm prog (DEC (Deref DX)) "decr (post)";
                | M_PRE_INC -> (
                    decl_asm prog (INC (Deref DX)) "incr (pre)";
                    decl_asm prog (INC (Reg AX)) " +";
                )
                | M_PRE_DEC -> (
                    decl_asm prog (DEC (Deref DX)) "decr (pre)";
                    decl_asm prog (DEC (Reg AX)) " +";
                )
        )
        | OP2 (op, lhs, rhs) -> (
            match op with
                | S_MUL -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth CX;
                    decl_asm prog (MUL (Reg CX)) "mul";
                )
                | S_MOD -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    decl_asm prog (MOV (Reg AX, Reg CX)) "";
                    retrieve depth AX;
                    decl_asm prog CQTO "";
                    decl_asm prog (DIV (Reg CX)) "div/mod";
                    decl_asm prog (MOV (Reg DX, Reg AX)) " + -> mod";
                )
                | S_DIV -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    decl_asm prog (MOV (Reg AX, Reg CX)) "";
                    retrieve depth AX;
                    decl_asm prog CQTO "";
                    decl_asm prog (DIV (Reg CX)) "div/mod -> div";
                )
                | S_ADD -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth CX;
                    decl_asm prog (ADD (Reg CX, Reg AX)) "add";
                )
                | S_SUB -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth CX;
                    decl_asm prog (NEG (Reg AX)) "sub: neg";
                    decl_asm prog (ADD (Reg CX, Reg AX)) "    & add";
                )
                | S_INDEX -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth CX;
                    decl_asm prog (LEA (Index (CX, AX), Reg DX)) "";
                    decl_asm prog (MOV (Deref DX, Reg AX)) "";
                )
        )
        | CMP (op, lhs, rhs) -> (
            gen_expr (depth, frame, label) lhs;
            store depth AX;
            gen_expr (depth+1, frame, label) rhs;
            retrieve depth CX;
            decl_asm prog (CMP (Reg AX, Reg CX)) "compare";
            let tagbase = sprintf "%d_cmp_" !label_cnt in
            incr label_cnt;
            match op with
                | C_LT -> (
                    decl_asm prog (JLT (label, tagbase ^ "lt")) "case <";
                    decl_asm prog (MOV (Const 0, Reg AX)) "";
                    decl_asm prog (JMP (label, tagbase ^ "done")) " +";
                    decl_asm prog (TAG (label, tagbase ^ "lt")) " +";
                    decl_asm prog (MOV (Const 1, Reg AX)) " +";
                    decl_asm prog (TAG (label, tagbase ^ "done")) " +";
                )
                | C_LE -> (
                    decl_asm prog (JLE (label, tagbase ^ "le")) "case <=";
                    decl_asm prog (MOV (Const 0, Reg AX)) " +";
                    decl_asm prog (JMP (label, tagbase ^ "done")) " +";
                    decl_asm prog (TAG (label, tagbase ^ "le")) " +";
                    decl_asm prog (MOV (Const 1, Reg AX)) " +";
                    decl_asm prog (TAG (label, tagbase ^ "done")) " +";
                )
                | C_EQ -> (
                    decl_asm prog (JEQ (label, tagbase ^ "eq")) "case ==";
                    decl_asm prog (MOV (Const 0, Reg AX)) " +";
                    decl_asm prog (JMP (label, tagbase ^ "done")) " +";
                    decl_asm prog (TAG (label, tagbase ^ "eq")) " +";
                    decl_asm prog (MOV (Const 1, Reg AX)) " +";
                    decl_asm prog (TAG (label, tagbase ^ "done")) " +";
                )
        )
        | EIF (cond, expr_true, expr_false) -> (
            let tagbase = sprintf "%d_tern_" !label_cnt in
            incr label_cnt;
            gen_expr (depth, frame, label) cond;
            decl_asm prog (CMP (Const 0, Reg AX)) "apply ternary";
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
        | (CFUN _) :: tl -> get_global_vars tl
        | (CDECL (_, name)) :: tl -> (
            decl_int prog name;
            (name, (Glob name)) :: (get_global_vars tl)
        )
    in
    let universal = [
        ("stdin", Glob "stdin"); ("stdout", Glob "stdout"); ("stderr", Glob "stderr");
        ("SIZE", Const 8); ("EOF", Const (-1)); ("NULL", Const 0);
        ("true", Const 1); ("false", Const 0)
    ] in
    let global = get_global_vars decl_list in
    List.iter (gen_decl (global::[universal])) decl_list;
    generate out prog


let compile out decl_list =
    if verify_scope decl_list then (
        global_decl out decl_list;
        generate_asm out decl_list;
    )
