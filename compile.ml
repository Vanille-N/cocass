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

(* a tree to represent a jump table *)
type case_tree =
    | Default
    | Branch of int * case_tree * case_tree

let tree_of_cases arr =
    let n = Array.length arr in
    let rec build i j =
        if i < j then (
            let midpoint = (i + j) / 2 in
            Branch (arr.(midpoint), build i midpoint, build (midpoint+1) j)
        ) else (
            Default
        )
    in
    build 0 n

let extract_switch_cases cases =
    let rec dup = function
        | [] -> None
        | (_, a) :: (loc, b) :: _ when a = b -> Some (loc, b)
        | _ :: tl -> dup tl
    in
    let tags = List.map (fun (loc, c, _) -> (loc, c)) cases in
    let sorted = List.sort (fun (_, e1) (_, e2) -> compare e1 e2) tags in
    match dup sorted with
        | Some dup -> Error dup
        | None -> Ok (tree_of_cases (Array.of_list (List.map snd sorted)))

let find_duplicate_catch catches =
    let rec dup = function
        | [] -> None
        | (_, a) :: (loc, b) :: _ when a = b -> Some (loc, b)
        | _ :: tl -> dup tl
    in
    let rec wildcard_is_last = function
        | [] -> None
        | (_, "_") :: [] -> None
        | (loc, "_") :: tl -> Some loc
        | _ :: tl -> wildcard_is_last tl
    in
    let tags = List.map (fun (loc, e, _, _) -> (loc, e)) catches in
    let sorted = List.stable_sort (fun (_, e1) (_, e2) -> compare e1 e2) tags in
    match wildcard_is_last tags with
        | None -> dup sorted
        | Some loc -> Some (loc, "_")

let find_duplicate_decl decls =
    let rec dup = function
        | [] -> None
        | (_, a) :: (loc, b) :: _ when a = b -> Some (loc, b)
        | _ :: tl -> dup tl
    in
    let names = List.map (function
        | CDECL (loc, name) -> (loc, name)
        | CFUN (loc, name, _, _) -> (loc, name)
    ) decls in
    dup (List.stable_sort (fun (_, e1) (_, e2) -> compare e1 e2) names)

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
 *
 * Regarding exceptions:
 * *** .exc_addr(%rip) is current handler address
 * *** .exc_base(%rip) is current handler base pointer
 * *** RAX is exception parameter
 * *** RDI is exception identifier if not NULL
 * <><><> <><> <><><>
 *)
let codegen decl_list =
    let label_cnt = ref 0 in
    let prog = make_prog () in
    let handler = ".exc_handler" in
    let handler_addr = ".exc_addr" in
    let handler_base = ".exc_base" in
    prog.int handler_addr;
    prog.int handler_base;
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
    let universal = [
        ("stdin", Globl "stdin"); ("stdout", Globl "stdout"); ("stderr", Globl "stderr");
        ("EOF", Const (-1)); ("NULL", Const 0);
        ("true", Const 1); ("false", Const 0);
        ("SIGABRT", Const 6); ("SIGFPE", Const 8); ("SIGILL", Const 4);
        ("SIGINT", Const 2); ("SIGSEGV", Const 11); ("SIGTERM", Const 15);
        ("RAND_MAX", Const 2147483647);
        ("QSIZE", Const 8); ("DSIZE", Const 4); ("WSIZE", Const 2); ("BSIZE", Const 1);
        ("LONG", Hexdc "ffffffff"); ("WORD", Hexdc "ffff"); ("BYTE", Hexdc "ff")
    ] in
    let consts = List.filter_map (function
        | (name, Const k) -> Some (name, k)
        | _ -> None
    ) universal in
    let rec gen_code (depth, frame) (label, tagbrk, tagcont, istry) code =
        match snd code with
            | CBLOCK (decl_lst, code_lst) -> (
                let frame = (make_scope depth decl_lst) :: frame in
                let depth = depth + List.length decl_lst in
                List.iter (gen_code (depth, frame) (label, tagbrk, tagcont, istry)) code_lst
            )
            | CEXPR expr -> (
                let expr = Reduce.redexp consts expr in
                gen_expr (depth, frame) (label, tagbrk, tagcont) expr
            )
            | CIF (cond, do_true, do_false) -> (
                let tagbase = sprintf "%d_cond" !label_cnt in
                incr label_cnt;
                gen_expr (depth, frame) (label, tagbrk, tagcont) (Reduce.redexp consts cond);
                prog.asm (TST (Regst RAX, Regst RAX)) "apply cond";
                prog.asm (JEQ (label, tagbase ^ "_false")) "";
                gen_code (depth, frame) (label, tagbrk, tagcont, istry) do_true;
                prog.asm (JMP (label, tagbase ^ "_done")) "end case true";
                prog.asm (TAG (label, tagbase ^ "_false")) "begin case false";
                gen_code (depth, frame) (label, tagbrk, tagcont, istry) do_false;
                prog.asm (TAG (label, tagbase ^ "_done")) "end ternary";
            )
            | CWHILE (cond, body, finally, test_at_start) -> (
                let tagbase = sprintf "%d_loop" !label_cnt in
                incr label_cnt;
                if test_at_start then prog.asm (JMP (label, tagbase ^ "_check")) "";
                prog.asm (TAG (label, tagbase ^ "_start")) "";
                gen_code (depth, frame) (label, Some tagbase, Some tagbase, istry) body;
                prog.asm (TAG (label, tagbase ^ "_finally")) "";
                (match finally with
                    | None -> ()
                    | Some e -> gen_expr (depth, frame) (label, Some tagbase, Some tagbase) (Reduce.redexp consts e)
                );
                prog.asm (TAG (label, tagbase ^ "_check")) "";
                gen_expr (depth, frame) (label, Some tagbase, Some tagbase) (Reduce.redexp consts cond);
                prog.asm (TST (Regst RAX, Regst RAX)) "";
                prog.asm (JNE (label, tagbase ^ "_start")) "";
                prog.asm (TAG (label, tagbase ^ "_done")) "";
            )
            | CRETURN None -> (
                if istry then Error.error (Some (fst code)) "you may not use return inside a try block"
                else (
                    prog.asm (MOV (Const 0, Regst RAX)) "return 0";
                    prog.asm (JMP (label, "return")) " +";
                )
            )
            | CRETURN (Some ret) -> (
                if istry then Error.error (Some (fst code)) "you may not use return inside a try block"
                else (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) (Reduce.redexp consts ret);
                    prog.asm (JMP (label, "return")) "return";
                )
            )
            | CBREAK -> (
                match tagbrk with
                    | None when istry -> Error.error (Some (fst code)) "break may not reach outside of try."
                    | None -> Error.error (Some (fst code)) "no loop to break out of."
                    | Some tagbrk -> prog.asm (JMP (label, tagbrk ^ "_done")) (sprintf "break out of %s" tagbrk)
            )
            | CCONTINUE -> (
                match tagcont with
                    | None when istry -> Error.error (Some (fst code)) "continue may not reach outside of try."
                    | None -> Error.error (Some (fst code)) "no loop to continue."
                    | Some tagcont -> prog.asm (JMP (label, tagcont ^ "_finally")) (sprintf "continue to next iteration of %s" tagcont)
            )
            | CSWITCH (e, cases, deflt) -> (
                let tagbase = sprintf "%d_switch" !label_cnt in
                incr label_cnt;
                prog.asm NOP "# enter switch";
                gen_expr (depth, frame) (label, tagbrk, tagcont) (Reduce.redexp consts e);
                match extract_switch_cases cases with
                    | Error (loc, c) -> Error.error (Some loc) (sprintf "duplicate case %d" c)
                    | Ok vals -> (
                        prog.asm NOP "# begin jump table";
                        (* List.iter (fun c ->
                            prog.asm (CMP (Const c, Regst RAX)) (sprintf "check against %d" c);
                            prog.asm (JEQ (label, tagbase ^ (tag_of_int c))) "";
                        ) vals; *)
                        let rec generate_tree = function
                            | Default -> prog.asm (JMP (label, tagbase ^ "_default")) "";
                            | Branch (k, Default, Default) -> (
                                prog.asm (CMP (Const k, Regst RAX)) (sprintf "check against %d" k);
                                prog.asm (JEQ (label, tagbase ^ (tag_of_int k))) "  -> match";
                                prog.asm (JNE (label, tagbase ^ "_default")) "";
                            )
                            | Branch (k, Branch (sm, sml, smr), Default) -> (
                                prog.asm (CMP (Const k, Regst RAX)) (sprintf "check against %d" k);
                                prog.asm (JEQ (label, tagbase ^ (tag_of_int k))) "  -> match";
                                prog.asm (JGT (label, tagbase ^ "_default")) "";
                                generate_tree (Branch (sm, sml, smr));
                            )
                            | Branch (k, Default, Branch (gt, gtl, gtr)) -> (
                                prog.asm (CMP (Const k, Regst RAX)) (sprintf "check against %d" k);
                                prog.asm (JEQ (label, tagbase ^ (tag_of_int k))) "  -> match";
                                prog.asm (JLT (label, tagbase ^ "_default")) "";
                                generate_tree (Branch (gt, gtl, gtr));
                            )
                            | Branch (k, smaller, greater) -> (
                                prog.asm (CMP (Const k, Regst RAX)) (sprintf "check against %d" k);
                                prog.asm (JEQ (label, tagbase ^ (tag_of_int k))) "  -> match";
                                prog.asm (JGT (label, tagbase ^ "_above" ^ (tag_of_int k))) "";
                                generate_tree smaller;
                                prog.asm (TAG (label, tagbase ^ "_above" ^ (tag_of_int k))) "";
                                generate_tree greater;
                            )
                        in
                        generate_tree vals;
                        prog.asm (JMP (label, tagbase ^ "_default")) "no match found";
                        prog.asm NOP "# end jump table";
                        List.iter (fun (_, c, blk) ->
                            prog.asm (TAG (label, tagbase ^ (tag_of_int c))) "";
                            List.iter (gen_code (depth, frame) (label, Some tagbase, tagcont, istry)) blk;
                        ) cases;
                        prog.asm (TAG (label, tagbase ^ "_default")) "";
                        gen_code (depth, frame) (label, Some tagbase, tagcont, istry) deflt;
                        prog.asm (TAG (label, tagbase ^ "_done")) "";
                        prog.asm NOP "# exit switch";
                    )
            )
            | CTHROW (name, value) -> (
                (if name = "_" then
                    Error.error (Some (fst code)) "wildcard _ exception may not be thrown.\n"
                );
                let id = prog.exc name in
                gen_expr (depth, frame) (label, tagbrk, tagcont) (Reduce.redexp consts value);
                prog.asm (LEA (Globl id, Regst RDI)) (sprintf "id for exception %s" name);
                prog.asm (LEA (Globl handler_base, Regst RSI)) "load handler_base";
                prog.asm (MOV (Deref RSI, Regst RBP)) "restore base pointer for handler";
                prog.asm (LEA (Globl handler_addr, Regst RSI)) "load handler_addr";
                prog.asm (MOV (Deref RSI, Regst RSI)) " +";
                prog.asm (JMP ("", "*%rsi")) "";
            )
            | CTRY (code, catches, finally) -> (
                (match find_duplicate_catch catches with
                    | None -> ()
                    | Some (loc, "_") -> Error.error (Some loc) "all catch clauses after wildcard _ are unreachable.\n"
                    | Some (loc, e) -> Error.error (Some loc) (sprintf "duplicate catch. %s is already handled by a previous clause.\n" e)
                );
                let tagbase = sprintf "%d_try" !label_cnt in
                incr label_cnt;
                (* INIT TRY *)
                prog.asm NOP "# enter try block";
                prog.asm (LEA (Globl handler_addr, Regst RSI)) "save previous handler addr";
                prog.asm (MOV (Deref RSI, Regst RAX)) " +";
                store depth RAX;
                prog.asm (LEA (Globl (label ^ "." ^ tagbase ^ "_catch"), Regst RAX)) "new handler addr";
                prog.asm (MOV (Regst RAX, Deref RSI)) " +";
                prog.asm (LEA (Globl handler_base, Regst RSI)) "save previous handler base";
                prog.asm (MOV (Deref RSI, Regst RAX)) " +";
                store (depth+1) RAX;
                prog.asm (MOV (Regst RBP, Deref RSI)) "new handler base";
                (* BEGIN TRY *)
                gen_code (depth+2, frame) (label, None, None, true) code;
                (* END TRY *)
                prog.asm NOP "# try block exited normally, remove handler";
                prog.asm (LEA (Globl handler_base, Regst RSI)) "";
                retrieve (depth+1) RCX;
                prog.asm (MOV (Regst RCX, Deref RSI)) "restore previous handler base";
                prog.asm (LEA (Globl handler_addr, Regst RSI)) "";
                retrieve depth RCX;
                prog.asm (MOV (Regst RCX, Deref RSI)) "restore previous handler addr";
                prog.asm (MOV (Const 0, Regst RDI)) "no unhandled exception remains";
                prog.asm (JMP (label, tagbase ^ "_finally")) "";
                (* BEGIN CATCH *)
                prog.asm (TAG (label, tagbase ^ "_catch")) "try block aborted, remove handler";
                prog.asm NOP " -> exception name is in %rdi";
                prog.asm NOP " -> exception parameter is in %rax";
                prog.asm (MOV (Regst RBP, Regst RSP)) "";
                prog.asm (LEA (Globl handler_base, Regst RSI)) "";
                retrieve (depth+1) RCX;
                prog.asm (MOV (Regst RCX, Deref RSI)) "restore previous handler base";
                prog.asm (LEA (Globl handler_addr, Regst RSI)) "";
                retrieve depth RCX;
                prog.asm (MOV (Regst RCX, Deref RSI)) "restore previous handler addr";
                List.iter (fun (_, name, bind, handle) -> (
                    if name <> "_" then (
                        let id = prog.exc name in
                        prog.asm (LEA (Globl id, Regst RSI)) "exception name";
                        prog.asm (CMP (Regst RDI, Regst RSI)) " + check against currently raised exception";
                        prog.asm (JNE (label, tagbase ^ "_not" ^ id)) "not a match";
                        if bind <> "_" then (
                            store depth RAX;
                            gen_code (depth+1, [(bind, Stack (-depth*8))] :: frame) (label, tagbrk, tagcont, istry) handle;
                        ) else (
                            (* _ does not induce a variable binding *)
                            gen_code (depth, frame) (label, tagbrk, tagcont, istry) handle;
                        );
                        prog.asm (MOV (Const 0, Regst RDI)) "mark as handled";
                        prog.asm (JMP (label, tagbase ^ "_finally")) "";
                        prog.asm (TAG (label, tagbase ^ "_not" ^ id)) "";
                    ) else (
                        (* _ matches any exception *)
                        prog.asm NOP "# wildcard exception";
                        if bind <> "_" then (
                            Error.error (Some (fst code)) "in next handler: wildcard exception may not induce a variable binding";
                        ) else (
                            (* _ does not induce a variable binding *)
                            gen_code (depth, frame) (label, tagbrk, tagcont, istry) handle;
                        );
                        prog.asm (MOV (Const 0, Regst RDI)) "mark as handled";
                        prog.asm (JMP (label, tagbase ^ "_finally")) "";
                    )
                )) catches;
                (* BEGIN FINALLY *)
                prog.asm (TAG (label, tagbase ^ "_finally")) "";
                store depth RAX;
                store (depth+1) RDI;
                (match finally with
                    | None -> ()
                    | Some code -> gen_code (depth+2, frame) (label, tagbrk, tagcont, istry) code
                );
                (* MAYBE RETHROW *)
                retrieve (depth+1) RDI;
                prog.asm (CMP (Const 0, Regst RDI)) "check if exception was handled";
                prog.asm (JEQ (label, tagbase ^ "_end")) "done with the try block";
                retrieve depth RAX;
                prog.asm NOP "# no matching catch found, rethrow";
                prog.asm (LEA (Globl handler_base, Regst RSI)) "load handler_base";
                prog.asm (MOV (Deref RSI, Regst RBP)) "restore base pointer for handler";
                prog.asm (LEA (Globl handler_addr, Regst RSI)) "load handler_addr";
                prog.asm (MOV (Deref RSI, Regst RSI)) " +";
                prog.asm (JMP ("", "*%rsi")) "";
                prog.asm (TAG (label, tagbase ^ "_end")) "";
            )
    and enter_stackframe () =
        prog.asm (PSH (Regst RBP)) "enter stackframe";
        prog.asm (MOV (Regst RSP, Regst RBP)) " +";
    and leave_stackframe fname =
        prog.asm (XOR (Regst RAX, Regst RAX)) "set to 0";
        prog.asm (TAG (fname, "return")) "leave stackframe";
        prog.asm (POP (Regst RBP)) " +";
        prog.asm RET ""
    and stack_args decs =
        let n = List.length decs in
        let stacked = List.init (max 0 (n-6)) (fun i -> Stack (8*(i+2))) in
        let regged = truncate (min 6 n) [RDI; RSI; RDX; RCX; R08; R09] in
        let names = List.map extract_decl_name decs in
        let regged = List.mapi (fun i (loc, name) ->
            let newloc = Stack (-(i+1)*8) in
            prog.asm (MOV (Regst loc, newloc)) (sprintf "store %s" name);
            newloc
        ) (zip regged names) in
        let vars = zip names (regged @ stacked) in
        List.iter (fun (name, loc) -> match loc with
            | Stack k when k > 0 -> prog.asm NOP (sprintf "%s is at RBP+%d" name k)
            | _ -> ()
        ) vars;
        vars
    and make_scope depth decls =
        let n = List.length decls in
        let pos = List.init n (fun i -> Stack (-8*(i+depth))) in
        let names = List.map extract_decl_name decls in
        (match find_duplicate_decl decls with
            | None -> ()
            | Some (loc, name) -> Error.error (Some loc) (sprintf "redefinition of %s" name)
        );
        let vars = zip names pos in
        vars
    and store depth reg =
        prog.asm (MOV (Regst reg, Stack (-depth*8))) "store"
    and retrieve depth reg =
        prog.asm (MOV (Stack (-depth*8), Regst reg)) "retrieve"
    and gen_decl frame = function
        | CDECL (_, name) -> ()
        | CFUN (_, name, decs, code) -> (
            label_cnt := 0;
            prog.asm (FUN name) "toplevel function";
            (match find_duplicate_decl decs with
                | None -> ()
                | Some (loc, d) -> Error.error (Some loc) (sprintf "argument %s appears twice in the function declaration" d)
            );
            let nb_args = min 6 (List.length decs) in
            enter_stackframe ();
            let args = stack_args decs in
            (if name = "main" then (* setup exception handler *) (
                prog.asm (LEA (FnPtr handler, Regst RAX)) "init exception handler";
                prog.asm (LEA (Globl handler_addr, Regst RDI)) " +";
                prog.asm (MOV (Regst RAX, Deref RDI)) " +";
                prog.asm (LEA (Globl handler_base, Regst RDI)) " +";
                prog.asm (MOV (Regst RBP, Deref RDI)) " +";
            ));
            gen_code (nb_args+1, args :: frame) (name, None, None, false) code;
            leave_stackframe name;
        )
    and gen_expr (depth, frame) (label, tagbrk, tagcont) expr = match snd expr with
        | VAR name -> (match assoc name frame with
            | None -> Error.error (Some (fst expr)) (sprintf "cannot read from undeclared %s.\n" name)
            | Some (Const k) -> prog.asm (MOV (Const k, Regst RAX)) (sprintf "const val %s = %d" name k)
            | Some (Hexdc h) -> prog.asm (MOV (Hexdc h, Regst RAX)) (sprintf "const val %s = %s" name h)
            | Some (FnPtr f) -> prog.asm (LEA (FnPtr f, Regst RAX)) (sprintf "function pointer %s" f)
            | Some loc -> (
                prog.asm (LEA (loc, Regst RDI)) (sprintf "access %s" name);
                prog.asm (MOV (Deref RDI, Regst RAX)) (sprintf "read %s" name);
            )
        )
        | CST value -> prog.asm (MOV (Const value, Regst RAX)) (sprintf "load val %d" value);
        | STRING str -> (
            let name = prog.str str in
            prog.asm (LEA (Globl name, Regst RDI)) (sprintf "access %s" name);
            prog.asm (MOV (Regst RDI, Regst RAX)) (sprintf "read %s" name);
        )
        | SET_VAR (name, value) -> (
            gen_expr (depth, frame) (label, tagbrk, tagcont) value;
            match assoc name frame with
                | None -> Error.error (Some (fst expr)) (sprintf "cannot assign to undeclared %s.\n" name)
                | Some loc when is_addr loc -> (
                    prog.asm (LEA (loc, Regst RDI)) (sprintf "access %s" name);
                    prog.asm (MOV (Regst RAX, Deref RDI)) (sprintf "write %s" name);
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
                    prog.asm (MOV (loc, Regst RDI)) "access array";
                    prog.asm (LEA (Index (RDI, RCX), Regst RDI)) " +";
                    prog.asm (MOV (Regst RAX, Deref RDI)) " +";
                )
                | _ -> Error.error (Some (fst expr)) "need an lvalue to assign.\n"
        )
        | SET_DEREF (dest, value) -> (
            gen_expr (depth, frame) (label, tagbrk, tagcont) dest;
            store depth RAX;
            gen_expr (depth+1, frame) (label, tagbrk, tagcont) value;
            retrieve depth RDI;
            prog.asm (MOV (Regst RAX, Deref RDI)) "write to deref";
        )
        | OPSET_VAR _ | OPSET_ARRAY _ | OPSET_DEREF _ -> (
            let (op, value) = (match snd expr with
                | OPSET_VAR (op, name, value) -> (
                    (match assoc name frame with
                        | None -> Error.error (Some (fst expr)) (sprintf "cannot assign to undeclared %s.\n" name)
                        | Some loc when is_addr loc -> (
                            prog.asm (LEA (loc, Regst RDI)) (sprintf "access %s" name);
                        )
                        | _ -> Error.error (Some (fst expr)) "need an lvalue to assign.\n"
                    ); (op, value)
                )
                | OPSET_ARRAY (op, name, idx, value) -> (
                    (match assoc name frame with
                        | None -> Error.error (Some (fst expr)) (sprintf "cannot assign to undeclared %s.\n" name)
                        | Some loc when is_addr loc -> (
                            gen_expr (depth, frame) (label, tagbrk, tagcont) idx;
                            prog.asm (MOV (loc, Regst RDI)) "access array";
                            prog.asm (LEA (Index (RDI, RAX), Regst RDI)) " +";
                        )
                        | _ -> Error.error (Some (fst expr)) "need an lvalue to assign.\n"
                    ); (op, value)
                )
                | OPSET_DEREF (op, addr, value) -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) addr;
                    prog.asm (MOV (Regst RAX, Regst RDI)) "load address";
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
                        | S_ADD -> prog.asm (ADD (Regst RAX, Deref RDI)) "in-place add"
                        | S_SUB -> prog.asm (SUB (Regst RAX, Deref RDI)) "in-place sub"
                        | S_AND -> prog.asm (AND (Regst RAX, Deref RDI)) "in-place and"
                        | S_OR -> prog.asm (IOR (Regst RAX, Deref RDI)) "in-place incl. or"
                        | S_XOR -> prog.asm (XOR (Regst RAX, Deref RDI)) "in-place excl. or"
                        | _ -> failwith "unreachable @ compile::generate_asm::gen_expr::OPSET_*::S_ADD|..."
                    );
                    prog.asm (MOV (Deref RDI, Regst RAX)) " + load final value";
                )
                | S_MUL -> (
                    prog.asm NOP "extended mul";
                    prog.asm (MOV (Deref RDI, Regst RCX)) " + load current value";
                    prog.asm (MUL (Regst RCX)) " + calculate";
                    prog.asm (MOV (Regst RAX, Deref RDI)) " + store final value";
                )
                | S_MOD | S_DIV -> (
                    prog.asm NOP "extended div";
                    prog.asm (MOV (Regst RAX, Regst RCX)) " + move divisor";
                    prog.asm (MOV (Deref RDI, Regst RAX)) " + load dividend";
                    prog.asm QTO " +";
                    prog.asm (DIV (Regst RCX)) " + calculate";
                    (if op = S_MOD then
                        prog.asm (MOV (Regst RDX, Regst RAX)) " + select mod"
                    );
                    prog.asm (MOV (Regst RAX, Deref RDI)) " + store final value";
                )
                | S_SHL | S_SHR -> (
                    prog.asm NOP "in-place shift";
                    prog.asm (MOV (Regst RAX, Regst RCX)) " + shift amount";
                    (if op = S_SHL
                        then prog.asm (SHL (Regst CL, Deref RDI)) " + calculate shl"
                        else prog.asm (SHR (Regst CL, Deref RDI)) " + calculate shr"
                    );
                    prog.asm (MOV (Deref RDI, Regst RAX)) " + load final value";
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
                        prog.asm (MOV (loc, Regst RAX)) (sprintf "arg #%d" i);
                        prog.asm (MOV (Regst RAX, dest)) " +";
                    )
                    | Regst r -> prog.asm (MOV (loc, dest)) (sprintf "arg #%d" (i+1))
                    | _ -> failwith "unreachable @ compile::generate_asm::gen_expr::CALL::iter::_"
            ) moves;
            prog.asm (SUB (Const (offset*8), Regst RSP)) (sprintf "%d locals" (depth+nb_args));
            prog.asm (MOV (Const nb_stacked, Regst RAX)) (sprintf "varargs: %d on the stack" nb_stacked);
            (match assoc fname frame with
                | None | Some (FnPtr _) -> prog.asm (CAL fname) " +"
                | Some loc -> (
                    prog.asm (MOV (loc, Regst R10)) "function pointer";
                    prog.asm (CAL "*%r10") " +";
                )
            );
            prog.asm (MOV (Regst RBP, Regst RSP)) " +";
            if not (List.mem fname whitelist_longret)
            then prog.asm LTQ "";
        )
        | OP1 (op, expr) -> (
            gen_expr (depth, frame) (label, tagbrk, tagcont) expr;
            match op with
                | M_MINUS -> prog.asm (NEG (Regst RAX)) "negative"
                | M_NOT -> prog.asm (NOT (Regst RAX)) "bitwise not"
                | M_POST_INC -> if is_lvalue (snd expr)
                    then prog.asm (INC (Deref RDI)) "incr (post)"
                    else Error.error (Some (fst expr)) "increment needs an lvalue.\n"
                | M_POST_DEC -> if is_lvalue (snd expr)
                    then prog.asm (DEC (Deref RDI)) "decr (post)"
                    else Error.error (Some (fst expr)) "decrement needs an lvalue.\n"
                | M_PRE_INC -> if is_lvalue (snd expr)
                    then (
                        prog.asm (INC (Deref RDI)) "incr (pre)";
                        prog.asm (INC (Regst RAX)) " +";
                    ) else Error.error (Some (fst expr)) "increment needs an lvalue.\n"
                | M_PRE_DEC -> if is_lvalue (snd expr)
                    then (
                        prog.asm (DEC (Deref RDI)) "decr (pre)";
                        prog.asm (DEC (Regst RAX)) " +";
                    ) else Error.error (Some (fst expr)) "decrement needs an lvalue.\n"
                | M_DEREF -> (
                    prog.asm (MOV (Regst RAX, Regst RDI)) "deref";
                    prog.asm (MOV (Deref RAX, Regst RAX)) " +";
                )
                | M_ADDR -> if is_lvalue (snd expr)
                    then prog.asm (MOV (Regst RDI, Regst RAX)) "indir"
                    else Error.error (Some (fst expr)) "indirection needs an lvalue.\n"
        )
        | OP2 (op, lhs, rhs) -> (
            match op with
                | S_MUL -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                    retrieve depth RCX;
                    prog.asm (MUL (Regst RCX)) "mul";
                )
                | S_MOD | S_DIV -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                    prog.asm (MOV (Regst RAX, Regst RCX)) "";
                    retrieve depth RAX;
                    prog.asm QTO "";
                    prog.asm (DIV (Regst RCX)) "div/mod";
                    (if op = S_MOD then
                        prog.asm (MOV (Regst RDX, Regst RAX)) " -> mod"
                    );
                )
                | S_ADD | S_SUB -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                    retrieve depth RCX;
                    (if op = S_SUB then
                        prog.asm (NEG (Regst RAX)) "neg -> sub";
                    );
                    prog.asm (ADD (Regst RCX, Regst RAX)) "add";
                )
                | S_INDEX -> (
                    if is_lvalue (snd lhs) then (
                        gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                        store depth RAX;
                        gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                        retrieve depth RCX;
                        prog.asm (LEA (Index (RCX, RAX), Regst RDI)) "";
                        prog.asm (MOV (Deref RDI, Regst RAX)) "";
                    ) else (
                        Error.error (Some (fst expr)) "index requires an lvalue.\n"
                    )
                )
                | S_SHL | S_SHR -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                    prog.asm (MOV (Regst RAX, Regst RCX)) "";
                    retrieve depth RAX;
                    (if op = S_SHL
                        then prog.asm (SHL (Regst CL, Regst RAX)) ""
                        else prog.asm (SHR (Regst CL, Regst RAX)) ""
                    );
                )
                | S_AND | S_OR | S_XOR -> (
                    gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
                    store depth RAX;
                    gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
                    retrieve depth RCX;
                    (match op with
                        | S_AND -> prog.asm (AND (Regst RCX, Regst RAX)) "and"
                        | S_OR -> prog.asm (IOR (Regst RCX, Regst RAX)) "incl. or"
                        | S_XOR -> prog.asm (XOR (Regst RCX, Regst RAX)) "excl. or"
                        | _ -> failwith "unreachable @ compile::generate_asm::gen_expr::OP2::S_AND|..."
                    );
                )
        )
        | CMP (op, lhs, rhs) -> (
            gen_expr (depth, frame) (label, tagbrk, tagcont) lhs;
            store depth RAX;
            gen_expr (depth+1, frame) (label, tagbrk, tagcont) rhs;
            retrieve depth RCX;
            prog.asm (CMP (Regst RAX, Regst RCX)) "compare";
            let tagbase = sprintf "%d_cmp" !label_cnt in
            incr label_cnt;
            let (jump_instr, case_nojump, comment) = (match op with
                | C_LT -> (JLT (label, tagbase), 0, "case <")
                | C_LE -> (JLE (label, tagbase), 0, "case <=")
                | C_EQ -> (JEQ (label, tagbase), 0, "case ==")
                | C_GT -> (JLE (label, tagbase), 1, "case ! >")
                | C_GE -> (JLT (label, tagbase), 1, "case ! >=")
            ) in
            prog.asm jump_instr comment;
            prog.asm (MOV (Const case_nojump, Regst RAX)) " +";
            prog.asm (JMP (label, tagbase ^ "_done")) " +";
            prog.asm (TAG (label, tagbase)) " +";
            prog.asm (MOV (Const (1-case_nojump), Regst RAX)) " +";
            prog.asm (TAG (label, tagbase ^ "_done")) " +";
        )
        | EIF (cond, expr_true, expr_false) -> (
            let tagbase = sprintf "%d_tern" !label_cnt in
            incr label_cnt;
            gen_expr (depth, frame) (label, tagbrk, tagcont) cond;
            prog.asm (TST (Regst RAX, Regst RAX)) "apply ternary";
            prog.asm (JEQ (label, tagbase ^ "_false")) "";
            gen_expr (depth, frame) (label, tagbrk, tagcont) expr_true;
            prog.asm (JMP (label, tagbase ^ "_done")) "end case true";
            prog.asm (TAG (label, tagbase ^ "_false")) "begin case false";
            gen_expr (depth, frame) (label, tagbrk, tagcont) expr_false;
            prog.asm (TAG (label, tagbase ^ "_done")) "end ternary";
        )
        | ESEQ exprs -> List.iter (gen_expr (depth, frame) (label, tagbrk, tagcont)) exprs
    in
    let rec get_global_vars = function
        | [] -> []
        | (CFUN (_, name, _, _)) :: tl -> (name, FnPtr name) :: (get_global_vars tl)
        | (CDECL (_, name)) :: tl -> (
            prog.int name;
            (name, (Globl name)) :: (get_global_vars tl)
        )
    in
    (match find_duplicate_decl decl_list with
        | None -> ()
        | Some (loc, name) -> Error.error (Some loc) (sprintf "redefinition of %s" name)
    );
    let global = get_global_vars decl_list in
    (
        let fmt = prog.str "Unhandled exception %s(%d)\n" in
        prog.asm (FUN ".exc_handler") "handle uncaught exceptions";
        prog.asm NOP " -> exception name is in %rdi";
        prog.asm NOP " -> exception parameter is in %rax";
        prog.asm (MOV (Regst RAX, Regst RBX)) "save parameter";
        prog.asm (MOV (Regst RDI, Regst R12)) "save name";
        prog.asm (MOV (Globl "stdout", Regst RDI)) "1st arg is stdout";
        prog.asm (CAL "fflush") "flush output before error";
        prog.asm (MOV (Regst RBX, Regst RCX)) "4th arg is parameter";
        prog.asm (MOV (Regst R12, Regst RDX)) "3rd arg is name";
        prog.asm (LEA (Globl fmt, Regst RSI)) "2nd arg is format";
        prog.asm (MOV (Globl "stderr", Regst RDI)) "1st arg is stderr";
        prog.asm (MOV (Const 0, Regst RAX)) "no args on the stack";
        prog.asm (CAL "fprintf") "";
        prog.asm (MOV (Regst RBX, Regst RDI)) "value";
        prog.asm (MOV (Const 60, Regst RAX)) "code for exit";
        prog.asm SYS "";
    );
    List.iter (gen_decl (global::[universal])) decl_list;
    prog


let compile (out, color) decl_list =
    let prog = codegen decl_list in
    if !Error.error_count = 0 then
        prog.gen (out, color)
    else (
        Error.flush_error ();
        printf "%d errors were found, no assembler generated.\n" !Error.error_count;
        flush stdout;
        exit 100
    )
