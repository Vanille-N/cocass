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

let rec is_addr = function
    | Const _ | FnPtr _ -> false
    | _ -> true

let tag_of_int i = (if i < 0 then "_neg_" else "_pos_") ^ (string_of_int (abs i))

let extract_switch_cases cases =
    let rec is_unique = function
        | [] -> None
        | a :: [] -> None
        | a :: b :: tl when a = b -> Some a
        | _ :: tl -> is_unique tl
    in
    let tags = List.map (fun (_, c, _) -> c) cases in
    let sorted = List.sort compare tags in
    match is_unique sorted with
        | Some dup -> Error dup
        | None -> Ok tags


(* <><><> NOTE <><><>
 * Accross all the program, the following conventions are used:
 * *** RAX is last evaluated expression
 * *** RDI is last calculated address
 * *** RCX is extra register (mul operand, divisor, shift amount, array index)
 * *** R10 is function pointer
 *
 * They are added to the universal conventions and constraints:
 * *** RAX is return value and vararg count
 * *** RDI is 1'st argument
 * *** RSI is 2'nd argument
 * *** RDX is 3'rd argument and div extension
 * *** RCX is 4'th argument
 * *** R08 is 5'th argument
 * *** R09 is 6'th argument
 * <><><> <><> <><><>
 *)
let generate_asm decl_list =
    let label_cnt = ref 0 in
    let prog = make_prog () in
    let str_count = ref 0 in
    let handler = ".exc_handler" in
    let handler_addr = ".exc_addr" in
    let handler_base = ".exc_base" in
    decl_int prog handler_addr;
    decl_int prog handler_base;
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
    let rec gen_code (depth, frame) (label, tagbrk, tagcont) code =
        match snd code with
            | CBLOCK (decl_lst, code_lst) -> (
                let frame = (make_scope depth decl_lst) :: frame in
                let depth = depth + List.length decl_lst in
                List.iter (gen_code (depth, frame) (label, tagbrk, tagcont)) code_lst
            )
            | CEXPR expr -> gen_expr (depth, frame) (label, tagbrk, tagcont) expr
            | CIF (cond, do_true, do_false) -> (
                let tagbase = sprintf "%d_cond" !label_cnt in
                incr label_cnt;
                gen_expr (depth, frame) (label, tagbrk, tagcont) cond;
                decl_asm prog (TST (Regst RAX, Regst RAX)) "apply cond";
                decl_asm prog (JEQ (label, tagbase ^ "_false")) "";
                gen_code (depth, frame) (label, tagbrk, tagcont) do_true;
                decl_asm prog (JMP (label, tagbase ^ "_done")) "end case true";
                decl_asm prog (TAG (label, tagbase ^ "_false")) "begin case false";
                gen_code (depth, frame) (label, tagbrk, tagcont) do_false;
                decl_asm prog (TAG (label, tagbase ^ "_done")) "end ternary";
            )
            | CWHILE (cond, body, finally, test_at_start) -> (
                let tagbase = sprintf "%d_loop" !label_cnt in
                incr label_cnt;
                if test_at_start then decl_asm prog (JMP (label, tagbase ^ "_check")) "";
                decl_asm prog (TAG (label, tagbase ^ "_start")) "";
                gen_code (depth, frame) (label, Some tagbase, Some tagbase) body;
                decl_asm prog (TAG (label, tagbase ^ "_finally")) "";
                (match finally with
                    | None -> ()
                    | Some e -> gen_expr (depth, frame) (label, Some tagbase, Some tagbase) e
                );
                decl_asm prog (TAG (label, tagbase ^ "_check")) "";
                gen_expr (depth, frame) (label, Some tagbase, Some tagbase) cond;
                decl_asm prog (TST (Regst RAX, Regst RAX)) "";
                decl_asm prog (JNE (label, tagbase ^ "_start")) "";
                decl_asm prog (TAG (label, tagbase ^ "_done")) "";
            )
            | CRETURN None -> (
                decl_asm prog (MOV (Const 0, Regst RAX)) "return 0";
                decl_asm prog (JMP (label, "return")) " +";
            )
            | CRETURN (Some ret) -> (
                gen_expr (depth, frame) (label, tagbrk, tagcont) ret;
                decl_asm prog (JMP (label, "return")) "return";
            )
            | CBREAK -> (
                match tagbrk with
                    | None -> Error.error (Some (fst code)) "no loop to break out of"
                    | Some tagbrk -> decl_asm prog (JMP (label, tagbrk ^ "_done")) (sprintf "break out of %s" tagbrk)
            )
            | CCONTINUE -> (
                match tagcont with
                    | None -> Error.error (Some (fst code)) "no loop to continue"
                    | Some tagcont -> decl_asm prog (JMP (label, tagcont ^ "_finally")) (sprintf "continue to next iteration of %s" tagcont)
            )
            | CSWITCH (e, cases, deflt) -> (
                let tagbase = sprintf "%d_switch" !label_cnt in
                incr label_cnt;
                decl_asm prog NOP "enter switch";
                gen_expr (depth, frame) (label, tagbrk, tagcont) e;
                match extract_switch_cases cases with
                    | Error c -> Error.error (Some (fst code)) (sprintf "duplicate case %d" c)
                    | Ok vals -> (
                        decl_asm prog NOP "begin jump table";
                        List.iter (fun c ->
                            decl_asm prog (CMP (Const c, Regst RAX)) (sprintf "check against %d" c);
                            decl_asm prog (JEQ (label, tagbase ^ (tag_of_int c))) "";
                        ) vals;
                        decl_asm prog (JMP (label, tagbase ^ "_default")) "no match found";
                        decl_asm prog NOP "end jump table";
                        List.iter (fun (_, c, blk) ->
                            decl_asm prog (TAG (label, tagbase ^ (tag_of_int c))) "";
                            List.iter (gen_code (depth, frame) (label, Some tagbase, tagcont)) blk;
                        ) cases;
                        decl_asm prog (TAG (label, tagbase ^ "_default")) "";
                        gen_code (depth, frame) (label, Some tagbase, tagcont) deflt;
                        decl_asm prog (TAG (label, tagbase ^ "_done")) "";
                        decl_asm prog NOP "exit switch";
                    )
            )
            | CTHROW (name, value) -> (
                let id = decl_exc prog name in
                gen_expr (depth, frame) (label, tagbrk, tagcont) value;
                decl_asm prog (LEA (Globl id, Regst RDI)) (sprintf "id for exception %s" name);
                decl_asm prog (LEA (Globl handler_base, Regst RSI)) "load handler_base";
                decl_asm prog (MOV (Deref RSI, Regst RBP)) "restore base pointer for handler";
                decl_asm prog (LEA (Globl handler_addr, Regst RSI)) "load handler_addr";
                decl_asm prog (MOV (Deref RSI, Regst RSI)) " +";
                decl_asm prog (JMP ("", "*%rsi")) "";
            )
    and enter_stackframe () =
        decl_asm prog (PSH (Regst RBP)) "enter stackframe";
        decl_asm prog (MOV (Regst RSP, Regst RBP)) " +";
    and leave_stackframe fname =
        decl_asm prog (XOR (Regst RAX, Regst RAX)) "set to 0";
        decl_asm prog (TAG (fname, "return")) "leave stackframe";
        decl_asm prog (POP (Regst RBP)) " +";
        decl_asm prog RET ""
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
            | Stack k when k > 0 -> decl_asm prog NOP (sprintf "%s is at RBP+%d" name k)
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
            (if name = "main" then (* setup exception handler *) (
                decl_asm prog (LEA (FnPtr handler, Regst RAX)) "init exception handler";
                decl_asm prog (LEA (Globl handler_addr, Regst RDI)) " +";
                decl_asm prog (MOV (Regst RAX, Deref RDI)) " +";
                decl_asm prog (LEA (Globl handler_base, Regst RDI)) " +";
                decl_asm prog (MOV (Regst RBP, Deref RDI)) " +";
            ));
            gen_code (nb_args+1, args :: frame) (name, None, None) code;
            leave_stackframe name;
        )
    and gen_expr (depth, frame) (label, tagbrk, tagcont) expr = match snd expr with
        | VAR name -> (match assoc name frame with
            | None -> Error.error (Some (fst expr)) (sprintf "cannot read from undeclared %s.\n" name)
            | Some (Const k) -> decl_asm prog (MOV (Const k, Regst RAX)) (sprintf "const val %s = %d" name k)
            | Some (FnPtr f) -> decl_asm prog (LEA (FnPtr f, Regst RAX)) (sprintf "function pointer %s" f)
            | Some loc -> (
                decl_asm prog (LEA (loc, Regst RDI)) (sprintf "access %s" name);
                decl_asm prog (MOV (Deref RDI, Regst RAX)) (sprintf "read %s" name);
            )
        )
        | CST value -> decl_asm prog (MOV (Const value, Regst RAX)) (sprintf "load val %d" value);
        | STRING str -> (
            let name = sprintf ".LC%d" !str_count in
            incr str_count;
            decl_str prog name str;
            decl_asm prog (LEA (Globl name, Regst RDI)) (sprintf "access %s" name);
            decl_asm prog (MOV (Regst RDI, Regst RAX)) (sprintf "read %s" name);
        )
        | SET_VAR (name, value) -> (
            gen_expr (depth, frame) (label, tagbrk, tagcont) value;
            match assoc name frame with
                | None -> Error.error (Some (fst expr)) (sprintf "cannot assign to undeclared %s.\n" name)
                | Some loc when is_addr loc -> (
                    decl_asm prog (LEA (loc, Regst RDI)) (sprintf "access %s" name);
                    decl_asm prog (MOV (Regst RAX, Deref RDI)) (sprintf "write %s" name);
                )
                | _ -> Error.error (Some (fst expr)) "need an lvalue to assign.\n"
        )
        | SET_ARRAY (arr, idx, value) -> (
            match assoc arr frame with
                | None -> Error.error (Some (fst expr)) (sprintf "cannot assign to undeclared %s.\n" arr)
                | Some loc when is_addr loc -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) idx;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) value;
                    retrieve (depth) RCX;
                    decl_asm prog (MOV (loc, Regst RDI)) "access array";
                    decl_asm prog (LEA (Index (RDI, RCX), Regst RDI)) " +";
                    decl_asm prog (MOV (Regst RAX, Deref RDI)) " +";
                )
                | _ -> Error.error (Some (fst expr)) "need an lvalue to assign.\n"
        )
        | SET_DEREF (dest, value) -> (
            gen_expr (depth, frame) (label, tagbrk, tagcont) dest;
            store depth RAX;
            gen_expr (depth+1, frame) (label, tagbrk, tagcont) value;
            retrieve depth RDI;
            decl_asm prog (MOV (Regst RAX, Deref RDI)) "write to deref";
        )
        | OPSET_VAR _ | OPSET_ARRAY _ | OPSET_DEREF _ -> (
            let (op, value) = (match snd expr with
                | OPSET_VAR (op, name, value) -> (
                    (match assoc name frame with
                        | None -> Error.error (Some (fst expr)) (sprintf "cannot assign to undeclared %s.\n" name)
                        | Some loc when is_addr loc -> (
                            decl_asm prog (LEA (loc, Regst RDI)) (sprintf "access %s" name);
                        )
                        | _ -> Error.error (Some (fst expr)) "need an lvalue to assign.\n"
                    ); (op, value)
                )
                | OPSET_ARRAY (op, name, idx, value) -> (
                    (match assoc name frame with
                        | None -> Error.error (Some (fst expr)) (sprintf "cannot assign to undeclared %s.\n" name)
                        | Some loc when is_addr loc -> (
                            gen_expr (depth, frame) (label, tagbrk, tagcont) idx;
                            decl_asm prog (MOV (loc, Regst RDI)) "access array";
                            decl_asm prog (LEA (Index (RDI, RAX), Regst RDI)) " +";
                        )
                        | _ -> Error.error (Some (fst expr)) "need an lvalue to assign.\n"
                    ); (op, value)
                )
                | OPSET_DEREF (op, addr, value) -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) addr;
                    decl_asm prog (MOV (Regst RAX, Regst RDI)) "load address";
                    (op, value)
                )
                | _ -> failwith "unreachable @ compile::generate_asm::gen_expr::OPSET_*"
            ) in
            (* The address of our expression is in RDI *)
            store depth RDI;
            gen_expr (depth+1, frame) (label, tagbrk, tagcont) value;
            retrieve depth RDI;
            (match op with
                | S_ADD | S_SUB | S_AND | S_OR | S_XOR -> (
                    (match op with
                        | S_ADD -> decl_asm prog (ADD (Regst RAX, Deref RDI)) "in-place add"
                        | S_SUB -> decl_asm prog (SUB (Regst RAX, Deref RDI)) "in-place sub"
                        | S_AND -> decl_asm prog (AND (Regst RAX, Deref RDI)) "in-place and"
                        | S_OR -> decl_asm prog (IOR (Regst RAX, Deref RDI)) "in-place incl. or"
                        | S_XOR -> decl_asm prog (XOR (Regst RAX, Deref RDI)) "in-place excl. or"
                        | _ -> failwith "unreachable @ compile::generate_asm::gen_expr::OPSET_*::S_ADD|..."
                    );
                    decl_asm prog (MOV (Deref RDI, Regst RAX)) " + load final value";
                )
                | S_MUL -> (
                    decl_asm prog NOP "extended mul";
                    decl_asm prog (MOV (Deref RDI, Regst RCX)) " + load current value";
                    decl_asm prog (MUL (Regst RCX)) " + calculate";
                    decl_asm prog (MOV (Regst RAX, Deref RDI)) " + store final value";
                )
                | S_MOD | S_DIV -> (
                    decl_asm prog NOP "extended div";
                    decl_asm prog (MOV (Regst RAX, Regst RCX)) " + move divisor";
                    decl_asm prog (MOV (Deref RDI, Regst RAX)) " + load dividend";
                    decl_asm prog QTO " +";
                    decl_asm prog (DIV (Regst RCX)) " + calculate";
                    (if op = S_MOD then
                        decl_asm prog (MOV (Regst RDX, Regst RAX)) " + select mod"
                    );
                    decl_asm prog (MOV (Regst RAX, Deref RDI)) " + store final value";
                )
                | S_SHL | S_SHR -> (
                    decl_asm prog NOP "in-place shift";
                    decl_asm prog (MOV (Regst RAX, Regst RCX)) " + shift amount";
                    (if op = S_SHL
                        then decl_asm prog (SHL (Regst CL, Deref RDI)) " + calculate shl"
                        else decl_asm prog (SHR (Regst CL, Deref RDI)) " + calculate shr"
                    );
                    decl_asm prog (MOV (Deref RDI, Regst RAX)) " + load final value";
                )
                | S_INDEX -> Error.error (Some (fst expr)) "INDEX cannot perform extended assign.\n"
            );
        )
        | CALL (fname, expr_lst) -> (
            List.iteri (fun i e ->
                gen_expr (depth+i, frame) (label, tagbrk, tagcont) e;
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
                    | Regst r -> decl_asm prog (MOV (loc, dest)) (sprintf "%d'th arg" (i+1))
                    | _ -> failwith "unreachable @ compile::generate_asm::gen_expr::CALL::iter::_"
            ) moves;
            decl_asm prog (SUB (Const (offset*8), Regst RSP)) (sprintf "%d locals" (depth+nb_args));
            decl_asm prog (MOV (Const nb_stacked, Regst RAX)) (sprintf "varargs: %d on the stack" nb_stacked);
            (match assoc fname frame with
                | None | Some (FnPtr _) -> decl_asm prog (CAL fname) " +"
                | Some loc -> (
                    decl_asm prog (MOV (loc, Regst R10)) "function pointer";
                    decl_asm prog (CAL "*%r10") " +";
                )
            );
            decl_asm prog (MOV (Regst RBP, Regst RSP)) " +";
            if not (List.mem fname whitelist_longret)
            then decl_asm prog LTQ "";
        )
        | OP1 (op, expr) -> (
            gen_expr (depth, frame) (label, tagbrk, tagcont) expr;
            match op with
                | M_MINUS -> decl_asm prog (NEG (Regst RAX)) "negative"
                | M_NOT -> decl_asm prog (NOT (Regst RAX)) "bitwise not"
                | M_POST_INC -> if is_lvalue (snd expr)
                    then decl_asm prog (INC (Deref RDI)) "incr (post)"
                    else Error.error (Some (fst expr)) "increment needs an lvalue.\n"
                | M_POST_DEC -> if is_lvalue (snd expr)
                    then decl_asm prog (DEC (Deref RDI)) "decr (post)"
                    else Error.error (Some (fst expr)) "decrement needs an lvalue.\n"
                | M_PRE_INC -> if is_lvalue (snd expr)
                    then (
                        decl_asm prog (INC (Deref RDI)) "incr (pre)";
                        decl_asm prog (INC (Regst RAX)) " +";
                    ) else Error.error (Some (fst expr)) "increment needs an lvalue.\n"
                | M_PRE_DEC -> if is_lvalue (snd expr)
                    then (
                        decl_asm prog (DEC (Deref RDI)) "decr (pre)";
                        decl_asm prog (DEC (Regst RAX)) " +";
                    ) else Error.error (Some (fst expr)) "decrement needs an lvalue.\n"
                | M_DEREF -> (
                    decl_asm prog (MOV (Regst RAX, Regst RDI)) "deref";
                    decl_asm prog (MOV (Deref RAX, Regst RAX)) " +";
                )
                | M_ADDR -> if is_lvalue (snd expr)
                    then decl_asm prog (MOV (Regst RDI, Regst RAX)) "indir"
                    else Error.error (Some (fst expr)) "indirection needs an lvalue.\n"
        )
        | OP2 (op, lhs, rhs) -> (
            match op with
                | S_MUL -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                    retrieve depth RCX;
                    decl_asm prog (MUL (Regst RCX)) "mul";
                )
                | S_MOD | S_DIV -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                    decl_asm prog (MOV (Regst RAX, Regst RCX)) "";
                    retrieve depth RAX;
                    decl_asm prog QTO "";
                    decl_asm prog (DIV (Regst RCX)) "div/mod";
                    (if op = S_MOD then
                        decl_asm prog (MOV (Regst RDX, Regst RAX)) " -> mod"
                    );
                )
                | S_ADD | S_SUB -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                    retrieve depth RCX;
                    (if op = S_SUB then
                        decl_asm prog (NEG (Regst RAX)) "neg -> sub";
                    );
                    decl_asm prog (ADD (Regst RCX, Regst RAX)) "add";
                )
                | S_INDEX -> (
                    if is_lvalue (snd lhs) then (
                        gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                        store depth RAX;
                        gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                        retrieve depth RCX;
                        decl_asm prog (LEA (Index (RCX, RAX), Regst RDI)) "";
                        decl_asm prog (MOV (Deref RDI, Regst RAX)) "";
                    ) else (
                        Error.error (Some (fst expr)) "index requires an lvalue.\n"
                    )
                )
                | S_SHL | S_SHR -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                    decl_asm prog (MOV (Regst RAX, Regst RCX)) "";
                    retrieve depth RAX;
                    (if op = S_SHL
                        then decl_asm prog (SHL (Regst CL, Regst RAX)) ""
                        else decl_asm prog (SHR (Regst CL, Regst RAX)) ""
                    );
                )
                | S_AND | S_OR | S_XOR -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                    retrieve depth RCX;
                    (match op with
                        | S_AND -> decl_asm prog (AND (Regst RCX, Regst RAX)) "and"
                        | S_OR -> decl_asm prog (IOR (Regst RCX, Regst RAX)) "incl. or"
                        | S_XOR -> decl_asm prog (XOR (Regst RCX, Regst RAX)) "excl. or"
                        | _ -> failwith "unreachable @ compile::generate_asm::gen_expr::OP2::S_AND|..."
                    );
                )
        )
        | CMP (op, lhs, rhs) -> (
            gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
            store depth RAX;
            gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
            retrieve depth RCX;
            decl_asm prog (CMP (Regst RAX, Regst RCX)) "compare";
            let tagbase = sprintf "%d_cmp" !label_cnt in
            incr label_cnt;
            let (jump_instr, case_nojump, comment) = (match op with
                | C_LT -> (JLT (label, tagbase), 0, "case <")
                | C_LE -> (JLE (label, tagbase), 0, "case <=")
                | C_EQ -> (JEQ (label, tagbase), 0, "case ==")
                | C_GT -> (JLE (label, tagbase), 1, "case ! >")
                | C_GE -> (JLT (label, tagbase), 1, "case ! >=")
            ) in
            decl_asm prog jump_instr comment;
            decl_asm prog (MOV (Const case_nojump, Regst RAX)) " +";
            decl_asm prog (JMP (label, tagbase ^ "_done")) " +";
            decl_asm prog (TAG (label, tagbase)) " +";
            decl_asm prog (MOV (Const (1-case_nojump), Regst RAX)) " +";
            decl_asm prog (TAG (label, tagbase ^ "_done")) " +";
        )
        | EIF (cond, expr_true, expr_false) -> (
            let tagbase = sprintf "%d_tern_" !label_cnt in
            incr label_cnt;
            gen_expr (depth, frame) (label, tagbrk, tagcont) cond;
            decl_asm prog (TST (Regst RAX, Regst RAX)) "apply ternary";
            decl_asm prog (JEQ (label, tagbase ^ "_false")) "";
            gen_expr (depth, frame) (label, tagbrk, tagcont) expr_true;
            decl_asm prog (JMP (label, tagbase ^ "_done")) "end case true";
            decl_asm prog (TAG (label, tagbase ^ "_false")) "begin case false";
            gen_expr (depth, frame) (label, tagbrk, tagcont) expr_false;
            decl_asm prog (TAG (label, tagbase ^ "_done")) "end ternary";
        )
        | ESEQ exprs -> List.iter (gen_expr (depth, frame) (label, tagbrk, tagcont)) exprs
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
    (
        decl_str prog ".LCEXC" "Unhandled exception %s(%d)\n";
        decl_asm prog (FUN ".exc_handler") "handle uncaught exceptions";
        decl_asm prog NOP " -> exception name is in %rdi";
        decl_asm prog NOP " -> exception parameter is in %rax";
        decl_asm prog (MOV (Regst RAX, Regst RBX)) "save parameter";
        decl_asm prog (MOV (Regst RDI, Regst RSI)) "2nd arg is name";
        decl_asm prog (MOV (Regst RAX, Regst RDX)) "3rd arg is parameter";
        decl_asm prog (LEA (Globl ".LCEXC", Regst RDI)) "1st arg is format";
        decl_asm prog (MOV (Const 0, Regst RAX)) "no args on the stack";
        decl_asm prog (CAL "printf") "";
        decl_asm prog (MOV (Regst RBX, Regst RDI)) "value";
        decl_asm prog (MOV (Const 60, Regst RAX)) "code for exit";
        decl_asm prog SYS "";
    );
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
