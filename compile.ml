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
    let prog = make_prog () in
    let str_count = ref 0 in
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
                decl_asm prog (MOV (Const 0, Reg AX)) "";
                decl_asm prog (JMP (label, "leave")) "";
            )
            | CRETURN (Some ret) -> (
                gen_expr (depth, frame, label) ret;
                decl_asm prog (JMP (label, "leave")) "";
            )
    and enter_stackframe () =
        decl_asm prog (PUSH (Reg BP)) "enter stackframe";
        decl_asm prog (MOV (Reg SP, Reg BP)) "";
    and leave_stackframe fname =
        decl_asm prog (MOV (Const 0, Reg AX)) "";
        decl_asm prog (TAG (fname, "leave")) "leave stackframe";
        decl_asm prog (POP (Reg BP)) "";
        if fname = "main" then (
            decl_asm prog (MOV (Reg AX, Reg DI)) "return value";
            decl_asm prog (MOV (Const 60, Reg AX)) "syscall code for exit";
            decl_asm prog SYS "";
        ) else (
            decl_asm prog RET "";
        )
    and stack_args decs =
        let n = List.length decs in
        let stacked = List.init (max 0 (n-6)) (fun i -> Stack (8*(i+2))) in
        let regged = truncate (min 6 n) [DI; SI; DX; CX; R8; R9] in
        let regged = List.mapi (fun i loc ->
            let newloc = Stack (-(i+1)*8) in
            decl_asm prog (MOV (Reg loc, newloc)) "";
            newloc
        ) regged in
        let names = List.map extract_decl_name decs in
        zip names (regged @ stacked)
    and make_scope depth decls =
        let n = List.length decls in
        let pos = List.init n (fun i -> Stack (-8*(i+depth))) in
        let names = List.map extract_decl_name decls in
        let vars = zip names pos in
        vars
    and store depth reg =
        decl_asm prog (MOV (Reg reg, Stack (-depth*8))) ""
    and retrieve depth reg =
        decl_asm prog (MOV (Stack (-depth*8), Reg reg)) ""
    and gen_decl global = function
        | CDECL (_, name) -> ()
        | CFUN (_, name, decs, code) -> (
            decl_asm prog (FUN name) "";
            let nb_args = min 6 (List.length decs) in
            enter_stackframe ();
            let args = stack_args decs in
            gen_code (nb_args+1, args :: [global], name) code;
            leave_stackframe name;
        )
    and gen_expr (depth, frame, label) expr = match snd expr with
        | VAR name -> (
            let loc = assoc name frame in
            decl_asm prog (LEA (loc, Reg BX)) (sprintf "access %s" name);
            decl_asm prog (MOV (Deref BX, Reg AX)) (sprintf "read from %s" name);
        )
        | CST value -> decl_asm prog (MOV (Const value, Reg AX)) (sprintf "load value %d" value);
        | STRING str -> (
            let name = sprintf "__str_%d" !str_count in
            incr str_count;
            decl_str prog name str;
            decl_asm prog (LEA (Glob name, Reg BX)) (sprintf "access %s" name);
            decl_asm prog (MOV (Reg BX, Reg AX)) (sprintf "read from %s" name);
        )
        | SET_VAR (name, expr) -> (
            gen_expr (depth, frame, label) expr;
            let loc = assoc name frame in
            decl_asm prog (LEA (loc, Reg BX)) (sprintf "access %s" name);
            decl_asm prog (MOV (Reg AX, Deref BX)) (sprintf "write to %s" name);
        )
        | SET_ARRAY (name, index, value) -> failwith "TODO set array"
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
            let stack_dests = List.init nb_stacked (fun i -> Stack (-(depth+nb_args+i)*8)) in
            let dests = reg_dests @ stack_dests in
            let locs = List.init nb_args (fun i -> Stack (-(depth+i)*8)) in
            let moves = zip locs dests in
            List.iter (fun (loc, dest) ->
                match dest with
                    | Stack k -> (
                        decl_asm prog (MOV (loc, Reg AX)) "";
                        decl_asm prog (MOV (Reg AX, dest)) "";
                    )
                    | Reg r -> decl_asm prog (MOV (loc, dest)) ""
                    | _ -> failwith "unreachable @ compile::generate_asm::gen_expr::CALL::iter::_"
            ) moves;
            decl_asm prog (SUB (Const ((depth+nb_args)*8), Reg SP)) "";
            decl_asm prog (MOV (Const nb_stacked, Reg AX)) "varargs";
            decl_asm prog (CALL fname) "";
            decl_asm prog (ADD (Const ((depth+nb_args)*8), Reg SP)) "";
        )
        | OP1 (op, expr) -> (
            gen_expr (depth, frame, label) expr;
            match op with
                | M_MINUS -> decl_asm prog (NEG (Reg AX)) "";
                | M_NOT -> decl_asm prog (NOT (Reg AX)) "";
                | M_POST_INC -> decl_asm prog (INC (Deref BX)) "";
                | M_POST_DEC -> decl_asm prog (DEC (Deref BX)) "";
                | M_PRE_INC -> (
                    decl_asm prog (INC (Deref BX)) "";
                    decl_asm prog (INC (Reg AX)) "";
                )
                | M_PRE_DEC -> (
                    decl_asm prog (DEC (Deref BX)) "";
                    decl_asm prog (DEC (Reg AX)) "";
                )
        )
        | OP2 (op, lhs, rhs) -> (
            match op with
                | S_MUL -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth CX;
                    decl_asm prog (MUL (Reg CX)) "";
                )
                | S_MOD -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    decl_asm prog (MOV (Reg AX, Reg CX)) "";
                    retrieve depth AX;
                    decl_asm prog CQTO "";
                    decl_asm prog (DIV (Reg CX)) "";
                    decl_asm prog (MOV (Reg DX, Reg AX)) "";
                )
                | S_DIV -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    decl_asm prog (MOV (Reg AX, Reg CX)) "";
                    retrieve depth AX;
                    decl_asm prog CQTO "";
                    decl_asm prog (DIV (Reg CX)) "";
                )
                | S_ADD -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth CX;
                    decl_asm prog (ADD (Reg CX, Reg AX)) "";
                )
                | S_SUB -> (
                    gen_expr (depth, frame, label) lhs;
                    store depth AX;
                    gen_expr (depth+1, frame, label) rhs;
                    retrieve depth CX;
                    decl_asm prog (NEG (Reg AX)) "";
                    decl_asm prog (ADD (Reg CX, Reg AX)) "";
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
            decl_int prog name;
            (name, (Glob name)) :: (get_global_vars tl)
        )
    in
    let global = get_global_vars decl_list in
    List.iter (gen_decl global) decl_list;
    generate out prog


let compile out decl_list =
    if verify_scope decl_list then (
        global_decl out decl_list;
        generate_asm out decl_list;
    )
