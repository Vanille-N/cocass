open Cparse
open CAST
open Generate
open Printf

module Vb = Verbose

(* utils *)

(* zip two lists together *)
let rec zip a b = match (a, b) with
    | (hdl::tll, hdr::tlr) -> (hdl,hdr) :: (zip tll tlr)
    | _ -> []

(* find if any item satisfies the condition *)
let any fn lst =
    let rec aux = function
        | [] -> false
        | hd :: tl when fn hd -> true
        | _ :: tl -> aux tl
    in aux lst

(* select n first items of lst *)
let rec truncate n lst =
    if lst = [] then []
    else if n = 0 then []
    else (List.hd lst) :: (truncate (n-1) (List.tl lst))

(* List.assoc_opt rewritten for ('a * 'b) list list *)
let assoc x ll =
    let rec aux = function
        | [] -> None
        | []::ll -> aux ll
        | ((h,y)::l)::ll when x = h -> Some y
        | (_::l)::ll -> aux (l::ll)
    in aux ll

(* is expression assignable to ? *)
let rec is_lvalue = function
    | VAR _ -> true
    | OP2 (S_INDEX, lhs, _) -> is_lvalue (snd lhs)
    | OP1 (M_DEREF, _) -> true
    | _ -> false

(* is location assignable to ? *)
let rec is_addr = function
    | Const _ | FnPtr _ -> false
    | _ -> true

let tag_of_int i = (if i < 0 then "_neg_" else "_pos_") ^ (string_of_int (abs i))

(* a tree to represent a jump table *)
type case_tree =
    | Default
    | Terminal of int
    | Branch of int * case_tree * case_tree

(* dichotomy on cases *)
let tree_of_cases arr =
    let n = Array.length arr in
    let rec build i j =
        if i+1 = j && i > 0 && j < n && arr.(i-1) + 2 = arr.(i+1) then (
            Terminal arr.(i)
        ) else if i < j then (
            let midpoint = (i + j) / 2 in
            Branch (arr.(midpoint), build i midpoint, build (midpoint+1) j)
        ) else (
            Default
        )
    in
    build 0 n

(* get cases from switch statement *)
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

(* detect useless catch *)
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

let reserved = ["va_start"; "va_arg"; "assert"]
let predefs = ["SIG_IGN"]

(* detect conflicting declaration *)
let find_duplicate_decl extractor decls =
    let rec dup = function
        | [] -> None
        | (_, a) :: (loc, b) :: _ when a = b -> Some (loc, b)
        | _ :: tl -> dup tl
    in
    let names = List.map extractor decls in
    List.iter (function
        | (loc, name) when List.mem name reserved || List.mem name predefs ->
            (Error.error (Some loc) (sprintf "%s is a reserved name" name))
        | _ -> ()
    ) names;
    dup (List.stable_sort (fun (_, e1) (_, e2) -> compare e1 e2) names)

(* determine if expression is trivial,
 * i.e. it requires no registers other than RAX
 * and is side-effect-free as well as side-effect-proof
 *)
let is_single_step = function
    | (_, CST _) -> true
    | (_, STRING _) -> true
    | _ -> false

(* get declaration name from var_declaration *)
let extract_decl_id = function
    | CDECL (id, _) -> id
    | CFUN (id, _, _) -> id

let extract_decl_name d = snd @@ extract_decl_id @@ d

(* predefined variables *)
let universal = [
    ("stdin", Globl "stdin"); ("stdout", Globl "stdout"); ("stderr", Globl "stderr");
    ("EOF", Const (-1)); ("NULL", Const 0);
    ("true", Const 1); ("false", Const 0);
    ("SIGABRT", Const 6); ("SIGFPE", Const 8); ("SIGILL", Const 4);
    ("SIGINT", Const 2); ("SIGSEGV", Const 11); ("SIGTERM", Const 15);
    ("SIGALRM", Const 14);
    ("SIG_IGN", Const 1); ("SIG_DFL", Const 0);
    ("O_RDONLY", Const 0); ("O_WRONLY", Const 1); ("O_RDWR", Const 2);
    ("O_APPEND", Const 1024); ("O_CREAT", Const 64); ("O_TRUNC", Const 512);
    ("STDIN_FILENO", Const 0); ("STDOUT_FILENO", Const 1); ("STDERR_FILENO", Const 2);
    ("RAND_MAX", Const 2147483647);
    ("QSIZE", Const 8); ("DSIZE", Const 4); ("WSIZE", Const 2); ("BSIZE", Const 1);
    ("LONG", Hexdc "ffffffff"); ("WORD", Hexdc "ffff"); ("BYTE", Const 255);
]

type arity =
    | Exact of int
    | More of int
    | Fewer of int
    | Any

(* arity, needs-conversion? *)
type fn_descriptor = arity * bool

(* a selection of functions from the standard library *)
(* format : (name, (arity, needs-conversion?)) *)
let stdlib = [
    ("abs", (Exact 1, true));
    ("atoi", (Exact 1, true));
    ("atol", (Exact 1, false));
    ("alarm", (Exact 1, false));
    ("bsearch", (Exact 5, false));
    ("close", (Exact 1, false));
    ("creat", (More 2, true));
    ("dup", (Exact 1, true));
    ("dup2", (Exact 2, true));
    ("execl", (More 2, true));
    ("execlp", (More 2, true));
    ("execv", (Exact 2, true));
    ("execvp", (Exact 2, true));
    ("exit", (Exact 1, false));
    ("fclose", (Exact 1, false));
    ("feof", (Exact 1, true));
    ("fflush", (Exact 1, false));
    ("fgetc", (Exact 1, true));
    ("fgets", (Exact 3, false));
    ("fopen", (Exact 2, false));
    ("fork", (Exact 0, true));
    ("fprintf", (More 2, false));
    ("fputc", (Exact 2, false));
    ("fputs", (Exact 2, false));
    ("free", (Exact 1, false));
    ("fscanf", (More 2, false));
    ("getc", (Exact 1, true));
    ("getchar", (Exact 0, true));
    ("getenv", (Exact 1, false));
    ("getpid", (Exact 0, true));
    ("getppid", (Exact 0, true));
    ("gets", (Exact 1, false));
    ("isalnum", (Exact 1, true));
    ("isalpha", (Exact 1, true));
    ("isascii", (Exact 1, true));
    ("isblank", (Exact 1, true));
    ("iscntrl", (Exact 1, true));
    ("isdigit", (Exact 1, true));
    ("isgraph", (Exact 1, true));
    ("islower", (Exact 1, true));
    ("isprint", (Exact 1, true));
    ("ispunct", (Exact 1, true));
    ("isspace", (Exact 1, true));
    ("isupper", (Exact 1, true));
    ("isxdigit", (Exact 1, true));
    ("kill", (Exact 2, false));
    ("labs", (Exact 1, false));
    ("malloc", (Exact 1, false));
    ("memchr", (Exact 3, false));
    ("memcmp", (Exact 3, true));
    ("memcpy", (Exact 3, false));
    ("memmove", (Exact 3, false));
    ("memset", (Exact 3, false));
    ("open", (More 2, true));
    ("perror", (Exact 1, false));
    ("pipe", (Exact 1, false));
    ("printf", (More 1, false));
    ("putc", (Exact 2, false));
    ("putchar", (Exact 1, false));
    ("putenv", (Exact 1, false));
    ("puts", (Exact 1, false));
    ("qsort", (Exact 4, false));
    ("rand", (Exact 0, true));
    ("read", (Exact 3, true));
    ("realloc", (Exact 2, false));
    ("sbrk", (Exact 1, false));
    ("scanf", (More 1, false));
    ("setpgid", (Exact 2, false));
    ("signal", (Exact 2, false));
    ("sleep", (Exact 1, false));
    ("srand", (Exact 1, false));
    ("strcat", (Exact 2, false));
    ("strchr", (Exact 2, false));
    ("strcmp", (Exact 2, true));
    ("strcpy", (Exact 2, false));
    ("strlen", (Exact 1, true));
    ("strtol", (Exact 1, false));
    ("system", (Exact 1, false));
    ("tolower", (Exact 1, true));
    ("toupper", (Exact 1, true));
    ("usleep", (Exact 1, false));
    ("wait", (Exact 1, true));
    ("waitpid", (Exact 3, false));
    ("write", (Exact 3, false));
]

(* stdlib + user-defined *)
let defined_functions decl_lst =
    let rec aux = function
        | [] -> stdlib
        | (CFUN ((_, name), (_, "...") :: fixed, _)) :: tl ->
            (name, (More (List.length fixed), false)) :: aux tl
        | (CFUN ((_, name), params, _)) :: tl ->
            (name, (Exact (List.length params), false)) :: aux tl
        | _ :: tl -> aux tl
    in
    aux decl_lst

(* matches arity *)
let satisfies ar n =
    match ar with
        | Any -> true
        | Exact i -> i = n
        | Fewer i -> i >= n
        | More i -> i <= n

(* for error reporting *)
let str_of_arity = function
    | Any -> "any"
    | Exact i -> sprintf "exactly %d" i
    | Fewer i -> sprintf "at most %d" i
    | More i -> sprintf "at least %d" i

(* those of the predefined variables that are decimal constant values *)
let consts = List.filter_map (function
    | (name, Const k) -> Some (name, k)
    | _ -> None
) universal

type generation_target = Value | Address | Both
let needs_address t = t <> Value
let needs_value t = t <> Address

let sup_target a b =
    match (needs_value a || needs_value b, needs_address a || needs_address b) with
        | true, true -> Both
        | true, false -> Value
        | false, true -> Address
        | _ -> failwith "unreachable @ sup_target::_"

(* <><><> NOTE <><><>
 * Accross all the program, the following conventions are used:
 * *** RAX is last evaluated expression
 * *** RDI is last calculated address
 * *** RCX is extra register (mul operand, divisor, shift amount, array index)
 * *** R10 is function pointer
 * *** .LCn are strings
 * *** .EXn are exceptions
 *
 * They are added to the universal conventions and constraints:
 * *** RAX is return value
 * *** RDI is 1'st argument
 * *** RSI is 2'nd argument
 * *** RDX is 3'rd argument and div extension
 * *** RCX is 4'th argument
 * *** R08 is 5'th argument
 * *** R09 is 6'th argument
 *
 * Regarding exceptions:
 * *** .eaddr(%rip) is current handler address
 * *** .ebase(%rip) is current handler base pointer
 * *** RAX is exception parameter
 * *** RDI is exception identifier if not NULL
 * <><><> <><> <><><>
 *)
let codegen decl_list =
    Vb.info None "starting compilation";
    let (label_id, reset_label_cnt) =
        let counter = ref 0 in
        (
            (fun () -> let c = !counter in incr counter; c),
            (fun () -> counter := 0)
        )
    in
    let prog = make_prog () in
    let handler = ".ehandler" in
    let handler_addr = ".eaddr" in
    let handler_base = ".ebase" in
    (* declare exception-related globals *)
    prog.int handler_addr 0;
    prog.int handler_base 0;
    let descriptors = defined_functions decl_list in
    let enter_stackframe () =
        prog.asm (PSH (Regst RBP)) "enter stackframe";
        prog.asm (MOV (Regst RSP, Regst RBP)) " +";
    and leave_stackframe fname =
        prog.asm (XOR (Regst RAX, Regst RAX)) "set to 0";
        prog.asm (TAG (fname, "return")) "leave stackframe";
        prog.asm (POP (Regst RBP)) " +";
        prog.asm RET ""
    and stack_args decs =
        (* put registers on the stack and record their position *)
        let n = List.length decs in
        let stacked = List.init (max 0 (n-6)) (fun i -> Stack (i+2)) in
        let regged = truncate (min 6 n) [RDI; RSI; RDX; RCX; R08; R09] in
        let names = List.map snd decs in
        List.iter (fun name -> Vb.detail (sprintf "argument: %s" name)) names;
        let regged = List.mapi (fun i (loc, name) ->
            let newloc = Stack (-i-1) in
            prog.asm (MOV (Regst loc, newloc)) (sprintf "store %s" name);
            newloc
        ) (zip regged names) in
        let vars = zip names (regged @ stacked) in
        List.iter (fun (name, loc) -> match loc with
            | Stack k when k > 0 -> (
                prog.asm NOP (sprintf "%s is at RBP+%d*8" name k)
            )
            | _ -> ()
        ) vars;
        vars
    and make_scope depth (decls:local_declaration list) =
        (* allocate space for local variables and record their position *)
        let n = List.length decls in
        let pos = List.init n (fun i -> Stack (-i-depth)) in
        let names = List.map (fun x -> snd @@ fst @@ x) decls in
        (match find_duplicate_decl fst decls with
            | None -> ()
            | Some (loc, name) -> Error.error (Some loc) (sprintf "redefinition of %s" name)
        );
        let vars = zip names pos in
        List.iter (fun name -> Vb.detail (sprintf "local: %s" name)) names;
        vars
    and store depth reg = (* save a temporary value on the top of the stack *)
        prog.asm (MOV (Regst reg, Stack (-depth))) "store"
    and retrieve depth reg = (* get a previously saved temporary value *)
        prog.asm (MOV (Stack (-depth), Regst reg)) "retrieve"
    in
    let rec gen_code envt tags istry code =
        let (depth, frame, va_depth) = envt in
        let (label, tagbrk, tagcont) = tags in
        let loc = fst code in
        match snd code with
            | CBLOCK code_lst -> (
                Vb.info (Some loc) "code block";
                let rec pipe envt = function
                    | [] -> ()
                    | code :: rest -> (
                        let envt = gen_code envt (label, tagbrk, tagcont) istry code in
                        pipe envt rest
                    )
                in pipe envt code_lst;
                envt
            )
            | CLOCAL declarations -> (
                Vb.info (Some loc) "local declaration";
                let newvars = make_scope depth declarations in
                let newdepth = depth + List.length declarations in
                let initvals = List.map (function
                    ((_, _), i) -> i
                ) declarations in
                List.iter (fun ((name, pos), init) ->
                    match init with
                        | None -> ()
                        | Some e -> (
                            gen_expr envt tags Value (Reduce.redexp consts e);
                            prog.asm (MOV (Regst RAX, pos)) (sprintf "initialise %s" name);
                        )
                ) (zip newvars initvals);
                (newdepth, newvars :: frame, va_depth)
            )
            | CEXPR expr -> (
                Vb.info (Some loc) "expression statement";
                let expr = Reduce.redexp consts expr in
                gen_expr envt tags Value expr;
                envt
            )
            | CIF (cond, do_true, do_false) -> (
                Vb.info (Some loc) "conditional branching";
                (* structure::if
                 *
                 *        begin
                 *        test cond
                 *        jump false ──────┐
                 *        exec do_true     │
                 *        jump ────────────│──┐
                 *        exec do_false <──┘  │
                 *        end <───────────────┘
                 *)
                let tagbase = sprintf "%d_cond" (label_id ()) in
                gen_expr envt tags Value (Reduce.redexp consts cond);
                prog.asm (TST (Regst RAX, Regst RAX)) "apply cond";
                prog.asm (JEQ (label, tagbase ^ "_false")) ""; (* jump over do_true *)
                let _ = gen_code envt tags istry do_true in
                prog.asm (JMP (label, tagbase ^ "_done")) "end case true"; (* jump over do_false *)
                prog.asm (TAG (label, tagbase ^ "_false")) "begin case false";
                let _ = gen_code envt tags istry do_false in
                prog.asm (TAG (label, tagbase ^ "_done")) "end ternary";
                envt
            )
            | CWHILE (cond, body, finally, test_at_start) -> (
                Vb.info (Some loc) "while loop";
                (* structure::while
                 *
                 *        begin
                 *        jump? ──────────┐    (not for do-while)
                 *        exec body <─────│─┐
                 *  ┌──── | (break)       │ │
                 *  │ ┌── | (continue)    │ │
                 *  │ └─> exec finally    │ │
                 *  │     test cond <─────┘ │
                 *  │     jump true ────────┘
                 *  └───> end
                 *)
                let tagbase = sprintf "%d_loop" (label_id ()) in
                if test_at_start then prog.asm (JMP (label, tagbase ^ "_check")) ""; (* do-while doesn't *)
                prog.asm (TAG (label, tagbase ^ "_start")) "";
                let _ = gen_code envt (label, Some tagbase, Some tagbase) istry body in
                prog.asm (TAG (label, tagbase ^ "_finally")) "";
                gen_expr envt (label, Some tagbase, Some tagbase) Value (Reduce.redexp consts finally); (* only in a for loop *)
                prog.asm (TAG (label, tagbase ^ "_check")) "";
                gen_expr envt (label, Some tagbase, Some tagbase) Value (Reduce.redexp consts cond);
                prog.asm (TST (Regst RAX, Regst RAX)) "";
                prog.asm (JNE (label, tagbase ^ "_start")) ""; (* loop to beginning *)
                prog.asm (TAG (label, tagbase ^ "_done")) "";
                envt
            )
            | CRETURN None -> (
                Vb.info (Some loc) "return none";
                if istry then Error.error (Some loc) "you may not use return inside a try block"
                else (
                    prog.asm (XOR (Regst RAX, Regst RAX)) "return 0";
                    prog.asm (JMP (label, "return")) " +";
                );
                envt
            )
            | CRETURN (Some ret) -> (
                Vb.info (Some loc) "return some";
                if istry then Error.error (Some loc) "you may not use return inside a try block"
                else (
                    gen_expr envt tags Value (Reduce.redexp consts ret);
                    prog.asm (JMP (label, "return")) "return";
                );
                envt
            )
            | CBREAK -> (
                Vb.info (Some loc) "break statement";
                (match tagbrk with
                    | None when istry -> Error.error (Some loc) "break may not reach outside of try."
                    | None -> Error.error (Some loc) "no loop to break out of."
                    | Some tagbrk -> prog.asm (JMP (label, tagbrk ^ "_done")) (sprintf "break out of %s" tagbrk)
                );
                envt
            )
            | CCONTINUE -> (
                Vb.info (Some loc) "continue statement";
                (match tagcont with
                    | None when istry -> Error.error (Some loc) "continue may not reach outside of try."
                    | None -> Error.error (Some loc) "no loop to continue."
                    | Some tagcont -> prog.asm (JMP (label, tagcont ^ "_finally")) (sprintf "continue to next iteration of %s" tagcont)
                );
                envt
            )
            | CSWITCH (e, cases, deflt) -> (
                Vb.info (Some loc) "switch block";
                (* structure::switch
                 *
                 *          begin
                 *          calc e
                 *          ...                              ─┐
                 *          case k <───────────────────┐      │
                 *          | compare k                │      │
                 *          | jump equal ────┐         │      ├─ jump table
                 *          | jump greater ──│─(k'>k)──┤      │  (binary search tree)
                 *          | jump smaller ──│─(k'<k)──┘      │
                 *          ...              │               ─┘
                 *          not found ───────│──┐
                 *          ...              │  │            ─┐
                 *      └─> exec k <─────────┘  │             │
                 *   ┌───── | (break)           │             ├─ execution
                 *   │  └─> ...                 │             │  (fallthrough)
                 *   │  └─> exec default <──────┘            ─┘
                 *   └────> end
                 *)
                let tagbase = sprintf "%d_switch" (label_id ()) in
                prog.asm NOP "# enter switch";
                gen_expr envt tags Value (Reduce.redexp consts e);
                (match extract_switch_cases cases with
                    | Error (loc, c) -> Error.error (Some loc) (sprintf "duplicate case %d" c)
                    | Ok vals -> (
                        prog.asm NOP "# begin jump table";
                        (* build the jump table from the binary search tree on cases *)
                        let rec generate_tree = function
                            | Default -> prog.asm (JMP (label, tagbase ^ "_default")) "";
                            | Terminal k -> prog.asm (JMP (label, tagbase ^ (tag_of_int k))) (sprintf "has to be %d" k);
                            | Branch (k, Default, Default) -> (
                                prog.asm (CMP (Const k, Regst RAX)) (sprintf "check against %d" k);
                                prog.asm (JEQ (label, tagbase ^ (tag_of_int k))) "  -> match";
                                prog.asm (JNE (label, tagbase ^ "_default")) "";
                            )
                            | Branch (k, smaller, Default) -> (
                                prog.asm (CMP (Const k, Regst RAX)) (sprintf "check against %d" k);
                                prog.asm (JEQ (label, tagbase ^ (tag_of_int k))) "  -> match";
                                prog.asm (JGT (label, tagbase ^ "_default")) "";
                                generate_tree smaller;
                            )
                            | Branch (k, Default, greater) -> (
                                prog.asm (CMP (Const k, Regst RAX)) (sprintf "check against %d" k);
                                prog.asm (JEQ (label, tagbase ^ (tag_of_int k))) "  -> match";
                                prog.asm (JLT (label, tagbase ^ "_default")) "";
                                generate_tree greater;
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
                            let _ = gen_code envt (label, Some tagbase, tagcont) istry blk in
                            ()
                        ) cases;
                        prog.asm (TAG (label, tagbase ^ "_default")) "";
                        let _ = gen_code envt (label, Some tagbase, tagcont) istry deflt in
                        prog.asm (TAG (label, tagbase ^ "_done")) "";
                        prog.asm NOP "# exit switch";
                    )
                );
                envt
            )
            | CTHROW (name, value) -> (
                Vb.info (Some loc) "throw statement";
                (if name = "_" then
                    Error.error (Some loc) "wildcard _ exception may not be thrown."
                );
                let id = prog.exc name in
                gen_expr envt tags Value (Reduce.redexp consts value);
                prog.asm (LEA (Globl id, Regst RDI)) (sprintf "id for exception %s" name);
                prog.asm (MOV (Globl handler_base, Regst RBP)) "restore base pointer for handler";
                prog.asm (MOV (Globl handler_addr, Regst RSI)) "restore stackframe for handler";
                prog.asm (JMP ("", "*%rsi")) "";
                envt
            )
            | CTRY (code, catches, finally) -> (
                Vb.info (Some loc) "try block";
                (* structure::try
                 *
                 *          begin
                 *          add handler          ─┐
                 *          exec body             ├─ try block
                 *   ┌───── | (throw)             │
                 *   │      del handler ────┐    ─┘
                 *   ├────> ... ────────────┤    ─┐
                 *   ├────> catch E         │     │
                 *   │      | del handler   │     ├─ handler
                 *   │      | exec catch ───┤     │
                 *   └────> ... ────────────┤    ─┘
                 *          finally <───────┘    ─┬─ closing
                 *      <── | rethrow?           ─┘
                 *          end
                 *
                 *)
                (match find_duplicate_catch catches with
                    | None -> ()
                    | Some (loc, "_") -> Error.warning (Some loc) "all catch clauses after wildcard _ are unreachable."
                    | Some (loc, e) -> Error.warning (Some loc) (sprintf "duplicate catch. %s is already handled by a previous clause." e)
                );
                let tagbase = sprintf "%d_try" (label_id ()) in
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
                let _ = gen_code (depth+2, frame, va_depth) (label, None, None) true code in
                Vb.info None "end try block";
                (* END TRY *)
                prog.asm NOP "# try block exited normally, remove handler";
                prog.asm (LEA (Globl handler_base, Regst RSI)) "";
                retrieve (depth+1) RCX; (* where we saved previous base *)
                prog.asm (MOV (Regst RCX, Deref RSI)) "restore previous handler base";
                prog.asm (LEA (Globl handler_addr, Regst RSI)) "";
                retrieve depth RCX; (* where we saved previous addr *)
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
                            let _ = gen_code (depth+1, [(bind, Stack (-depth))] :: frame, va_depth) tags istry handle in
                            ()
                        ) else (
                            (* _ does not induce a variable binding *)
                            let _ = gen_code envt tags istry handle in
                            ()
                        );
                        prog.asm (MOV (Const 0, Regst RDI)) "mark as handled";
                        prog.asm (JMP (label, tagbase ^ "_finally")) "";
                        prog.asm (TAG (label, tagbase ^ "_not" ^ id)) "";
                    ) else (
                        (* _ matches any exception *)
                        prog.asm NOP "# wildcard exception";
                        if bind <> "_" then (
                            Error.warning (Some loc) "in next handler: wildcard exception may not induce a variable binding";
                        ) else (
                            (* _ does not induce a variable binding *)
                            let _ = gen_code envt tags istry handle in
                            ()
                        );
                        prog.asm (MOV (Const 0, Regst RDI)) "mark as handled";
                        prog.asm (JMP (label, tagbase ^ "_finally")) "";
                    )
                )) catches;
                (* BEGIN FINALLY *)
                prog.asm (TAG (label, tagbase ^ "_finally")) "";
                store depth RAX;
                store (depth+1) RDI;
                let _ = gen_code (depth+2, frame, va_depth) tags istry finally in
                (* MAYBE RETHROW *)
                retrieve (depth+1) RDI;
                prog.asm (CMP (Const 0, Regst RDI)) "check if exception was handled";
                prog.asm (JEQ (label, tagbase ^ "_end")) "done with the try block";
                retrieve depth RAX;
                prog.asm NOP "# no matching catch found, rethrow";
                prog.asm (MOV (Globl handler_base, Regst RBP)) "restore base pointer for handler";
                prog.asm (MOV (Globl handler_addr, Regst RSI)) "load handler address";
                prog.asm (JMP ("", "*%rsi")) "";
                prog.asm (TAG (label, tagbase ^ "_end")) "";
                envt
            )
    and gen_decl frame = function
        | CDECL ((loc, name), _) -> Vb.info (Some loc) (sprintf "variable declaration: %s" name)
        | CFUN ((loc, name), decs, code) -> (
            Vb.info (Some loc) (sprintf "function declaration: %s" name);
            reset_label_cnt ();
            prog.asm (FUN name) "toplevel function";
            (match find_duplicate_decl (fun x -> x) decs with
                | None -> ()
                | Some (loc, d) -> Error.error (Some loc) (sprintf "argument %s appears twice in the function declaration" d)
            );
            match decs with
                | (_, "...") :: fixed -> (
                    Vb.detail "function is variadic";
                    (* variadic *)
                    if name = "main" then Error.error (Some loc) "main may not be variadic";
                    (* Mess with the stack a bit for future convenience :
                     *
                     *  [RDI:arg1] [RSI:arg2] [RDX:arg3] [RCX:arg4] [R08:arg5] [R09:arg6]
                     *     ...|arg9|arg8|arg7|addr| (free) ...
                     *                            ^ RSP
                     * becomes
                     *
                     *     ...|arg9|arg8|arg7|arg6|arg5|arg4|arg3|arg2|arg1|addr|base| (locals) ...
                     *                                                               ^ RSP=RBP
                     *)
                    prog.asm (MOV (Regst RBP, Regst R11)) "save base pointer";
                    prog.asm (SUB (Const (7*8), Regst RSP)) "move frame";
                    prog.asm (MOV (Regst RSP, Regst RBP)) " +";
                    prog.asm (MOV (Stack 7, Regst R10)) "save return address";
                    List.iteri (fun i r ->
                        prog.asm (MOV (Regst r, Stack (i+2))) "reg -> stack";
                    ) [RDI;RSI;RDX;RCX;R08;R09];
                    let nb_fixed = List.length fixed in
                    prog.asm (MOV (Regst R10, Stack 1)) "put back return address";
                    prog.asm (MOV (Regst R11, Stack 0)) "save previous base pointer";
                    let args = List.mapi (fun i (_, name) ->
                        Vb.detail (sprintf "argument: %s" name);
                        (name, Stack (i+2))
                    ) fixed in
                    let _ = gen_code (1, args :: frame, Some nb_fixed) (name, None, None) false code in
                    leave_stackframe name;
                )
                | _ -> (
                    (* normal case: non-variadic *)
                    (* Argument positioning:
                     *
                     *  [RDI:arg1] [RSI:arg2] [RDX:arg3] [RCX:arg4] [R08:arg5] [R09:arg6]
                     *     ...|arg9|arg8|arg7|addr| (free) ...
                     *                            ^ RSP
                     * becomes
                     *
                     *     ...|arg9|arg8|arg7|addr|base|arg1|arg2|arg3|arg4|arg5|arg6| (locals) ...
                     *                                 ^ RSP=RBP
                     *)
                    let nb_args = min 6 (List.length decs) in
                    enter_stackframe ();
                    let args = stack_args decs in
                    (if name = "main" && List.length decs > 2 then
                        Error.error (Some loc) "main takes at most two arguments"
                    );
                    (if name = "main" then (* setup emergency exception handler *) (
                        prog.asm (LEA (FnPtr handler, Regst RAX)) "init exception handler";
                        prog.asm (LEA (Globl handler_addr, Regst RDI)) " +";
                        prog.asm (MOV (Regst RAX, Deref RDI)) " +";
                        prog.asm (LEA (Globl handler_base, Regst RDI)) " +";
                        prog.asm (MOV (Regst RBP, Deref RDI)) " +";
                    ));
                    let _ = gen_code (nb_args+1, args :: frame, None) (name, None, None) false code in
                    leave_stackframe name;
                )
        )
    and gen_expr envt tags target expr =
        let (depth, frame, va_depth) = envt in
        let (label, tagbrk, tagcont) = tags in
        let loc = fst expr in
        match snd expr with
        | VAR name -> (match assoc name frame with
            | None -> Error.error (Some (fst expr)) (sprintf "cannot read from undeclared %s." name)
            | Some (Const k) -> (
                if (needs_address target) then Error.error (Some (fst expr)) "constant value has no address."
                else prog.asm (MOV (Const k, Regst RAX)) (sprintf "const val %s = %d" name k)
            )
            | Some (Hexdc h) -> (
                if (needs_address target) then Error.error (Some (fst expr)) "constant value has no address."
                else prog.asm (MOV (Hexdc h, Regst RAX)) (sprintf "const val %s = %s" name h)
            )
            | Some (FnPtr f) -> (
                if (needs_value target) then prog.asm (LEA (FnPtr f, Regst RAX)) (sprintf "function pointer %s" f);
                if (needs_address target) then prog.asm (LEA (FnPtr f, Regst RDI)) (sprintf "function pointer %s" f);
            )
            | Some loc -> (
                if (needs_address target) then (
                    prog.asm (LEA (loc, Regst RDI)) (sprintf "access %s" name);
                    if (needs_value target) then (
                        prog.asm (MOV (Deref RDI, Regst RAX)) (sprintf "read %s" name)
                    )
                ) else (
                    prog.asm (MOV (loc, Regst RAX)) (sprintf "read %s" name)
                )
            )
        )
        | CST value -> (
            if (needs_address target) then Error.error (Some loc) "constant value has no address."
            else prog.asm (MOV (Const value, Regst RAX)) (sprintf "load val %d" value)
        )
        | STRING str -> (
            let name = prog.str str in
            if (needs_address target) then Error.error (Some loc) "strings cannot be explicitly addressed";
            prog.asm (LEA (Globl name, Regst RAX)) (sprintf "read %s" name)
        )
        | SET (dest, value) -> (
            (if not @@ is_lvalue @@ snd @@ dest then Error.error (Some loc) "not an lvalue, cannot assign");
            gen_expr envt tags Value value;
            store depth RAX;
            gen_expr (depth+1, frame, va_depth) tags Address dest;
            retrieve depth RAX;
            prog.asm (MOV (Regst RAX, Deref RDI)) "write to deref";
        )
        | OPSET (op, dest, value) -> (
            (if not @@ is_lvalue @@ snd @@ dest then Error.error (Some loc) "not an lvalue, cannot perform extended assignment");
            gen_expr envt tags Value value;
            store depth RAX;
            gen_expr (depth+1, frame, va_depth) tags Both dest;
            (* The address of our expression is in RDI *)
            retrieve depth RAX;
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
                | S_INDEX -> Error.error (Some (fst expr)) "INDEX cannot perform extended assign."
            );
        )
        | CALL ("va_start", args) -> (
            let d = (match va_depth with
                | Some d -> d
                | None -> (Error.error (Some (fst expr)) "cannot init va in non-variadic function"; 0)
            ) in
            match args with
                | [e] -> (
                    (* init e to first optional argument *)
                    gen_expr envt tags Address e;
                    prog.asm (MOV (Const (d+2), Deref RDI)) "init first va";
                )
                | _ -> Error.error (Some (fst expr)) "va_init expects exactly one argument"
        )
        | CALL ("va_arg", args) -> (
            (match va_depth with
                | Some _ -> ()
                | None -> Error.error (Some (fst expr)) "cannot use va_arg in non-variadic function"
            );
            match args with
                | [e] -> (
                    (* thanks to our stack reorganization, next va is just increment e *)
                    gen_expr envt tags Both e;
                    prog.asm (MOV (Index (RBP, RAX), Regst RAX)) "load va";
                    prog.asm (INC (Deref RDI)) "prepare for next va";
                )
                | _ -> Error.error (Some (fst expr)) "va_arg expects exactly one argument"
        )
        | CALL ("assert", args) -> (
            match args with
                | [e] -> (
                    let tagbase = sprintf "%d_assert" (label_id ()) in
                    let (fname, nline, _, _, _) = fst expr in
                    let failure = sprintf "%s:%d" fname nline in
                    let msg = prog.str failure in
                    let ex = prog.exc "AssertionFailure" in
                    gen_expr envt tags Value e;
                    prog.asm (CMP (Const 0, Regst RAX)) "check assertion against 0";
                    prog.asm (JNE (label, tagbase ^ "_ok")) "";
                    (* assertion failed, throw an AssertionFailure *)
                    prog.asm (LEA (Globl ex, Regst RDI)) "id for exception AssertionFailure";
                    prog.asm (LEA (Globl msg, Regst RAX)) "failure line";
                    prog.asm (MOV (Globl handler_base, Regst RBP)) "restore base pointer for handler";
                    prog.asm (MOV (Globl handler_addr, Regst RSI)) "restore stackframe for handler";
                    prog.asm (JMP ("", "*%rsi")) "";
                    prog.asm (TAG (label, tagbase ^ "_ok")) "successful assertion";
                )
                | _ -> Error.error (Some (fst expr)) "assert expects exactly one argument"
        )
        | CALL (fname, expr_lst) -> (
            (* Argument positioning
             *
             *  [RDI:arg1] [RSI:arg2] [RDX:arg3] [RCX:arg4] [R08:arg5] [R09:arg6]
             *     ...|addr|base| (locals) (temp) ...|arg9|arg8|arg7|addr| (free) ...
             *                  ^ RBP                                    ^RSP
             *)
            let nb_args = List.length expr_lst in
            (match assoc fname frame with
                | None | Some (FnPtr _) -> (
                    match List.assoc_opt fname descriptors with
                        | Some (n, _) when not (satisfies n nb_args) -> Error.warning (Some (fst expr)) (sprintf "%s has the wrong arity: expected %s, got %d" fname (str_of_arity n) nb_args)
                        | None -> Error.warning (Some (fst expr)) (sprintf "unknown function %s" fname)
                        | _ -> ()
                )
                | _ -> ()
            );
            let nb_in_reg = min 6 nb_args in
            let nb_on_stk = nb_args - nb_in_reg in
            let reg_dests = truncate nb_in_reg (List.map (fun r -> Regst r) [RDI;RSI;RDX;RCX;R08;R09]) in
            let offset = (let base = depth + nb_on_stk in base + (base mod 2)) in (* 16-byte aligned *)
            (* temporary layout:
             * ...|addr|base| (locals) (temp) ...|arg9|arg8|arg7|arg6|arg5|...|arg1
             *                                                  ^move RSP here before call.
             *                                                   will overwrite register arguments
             *                                                                ^RSP+offset+nb_in_reg
             *)
            let stk_dests = List.init nb_args (fun i -> offset + nb_in_reg - i) in
            (* calculate all parameters *)
            List.iter (fun (e, d) ->
                gen_expr (d, frame, va_depth) tags Value e;
                store d RAX;
            ) (List.rev (zip expr_lst stk_dests));
            (* now load the first 6 into registers *)
            List.iter (fun (d, r) ->
                prog.asm (MOV (Stack (-d), r)) "";
            ) (zip stk_dests reg_dests);
            (* update stack pointer then call *)
            prog.asm (SUB (Const (8*offset), Regst RSP)) (sprintf "%d locals" (depth+nb_args));
            prog.asm (XOR (Regst RAX, Regst RAX)) "";
            (match assoc fname frame with
                | None | Some (FnPtr _) -> prog.asm (CAL fname) " +" (* unknown or known by tag *)
                | Some loc -> (
                    prog.asm (MOV (loc, Regst R10)) "function pointer"; (* known by address *)
                    prog.asm (CAL "*%r10") " +";
                )
            );
            prog.asm (MOV (Regst RBP, Regst RSP)) " +"; (* restore stackframe *)
            (match List.assoc_opt fname descriptors with
                | Some (_, true) | None -> prog.asm LTQ "" (* needs conversion 32 -> 64 *)
                | _ -> ()
            );
        )
        | OP1 (op, expr) -> (
            let op_requirements = match op with
                | M_PRE_DEC | M_PRE_INC | M_POST_DEC | M_POST_INC -> Both
                | M_ADDR -> Address
                | _ -> Value
            in (* these operators require us to know the address of our expression *)
            gen_expr envt tags (sup_target target op_requirements) expr;
            match op with
                | M_MINUS -> prog.asm (NEG (Regst RAX)) "negative"
                | M_NOT -> prog.asm (NOT (Regst RAX)) "bitwise not"
                | M_POST_INC -> if is_lvalue (snd expr)
                    then prog.asm (INC (Deref RDI)) "incr (post)"
                    else Error.error (Some (fst expr)) "increment needs an lvalue."
                | M_POST_DEC -> if is_lvalue (snd expr)
                    then prog.asm (DEC (Deref RDI)) "decr (post)"
                    else Error.error (Some (fst expr)) "decrement needs an lvalue."
                | M_PRE_INC -> if is_lvalue (snd expr)
                    then (
                        prog.asm (INC (Deref RDI)) "incr (pre)";
                        prog.asm (INC (Regst RAX)) " +";
                    ) else Error.error (Some (fst expr)) "increment needs an lvalue."
                | M_PRE_DEC -> if is_lvalue (snd expr)
                    then (
                        prog.asm (DEC (Deref RDI)) "decr (pre)";
                        prog.asm (DEC (Regst RAX)) " +";
                    ) else Error.error (Some (fst expr)) "decrement needs an lvalue."
                | M_DEREF -> (
                    prog.asm (MOV (Regst RAX, Regst RDI)) "deref";
                    prog.asm (MOV (Deref RAX, Regst RAX)) " +";
                )
                | M_ADDR -> if is_lvalue (snd expr)
                    then prog.asm (MOV (Regst RDI, Regst RAX)) "indir"
                    else Error.error (Some (fst expr)) "indirection needs an lvalue."
        )
        | OP2 (op, lhs, rhs) -> (
            match op with
                | S_MUL -> (
                    gen_expr envt tags Value rhs;
                    if is_single_step lhs then (
                        prog.asm (MOV (Regst RAX, Regst RCX)) "save rhs";
                        gen_expr envt tags Value lhs;
                    ) else (
                        store depth RAX;
                        gen_expr (depth+1, frame, va_depth) tags Value lhs;
                        retrieve depth RCX;
                    );
                    prog.asm (MUL (Regst RCX)) "mul";
                )
                | S_MOD | S_DIV -> (
                    gen_expr envt tags Value rhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, va_depth) tags Value lhs;
                    retrieve depth RCX;
                    prog.asm QTO "";
                    prog.asm (DIV (Regst RCX)) "div/mod";
                    (if op = S_MOD then
                        prog.asm (MOV (Regst RDX, Regst RAX)) " -> mod"
                    );
                )
                | S_ADD | S_SUB -> (
                    gen_expr envt tags Value rhs;
                    if is_single_step lhs then (
                        prog.asm (MOV (Regst RAX, Regst RCX)) "save rhs";
                        gen_expr envt tags Value lhs;
                    ) else (
                        store depth RAX;
                        gen_expr (depth+1, frame, va_depth) tags Value lhs;
                        retrieve depth RCX;
                    );
                    (if op = S_SUB
                        then prog.asm (SUB (Regst RCX, Regst RAX)) "sub"
                        else prog.asm (ADD (Regst RCX, Regst RAX)) "add"
                    );
                )
                | S_INDEX -> (
                    gen_expr envt tags Value rhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, va_depth) tags Value lhs;
                    prog.asm (MOV (Regst RAX, Regst RCX)) "move lhs";
                    retrieve depth RAX;
                    if (needs_address target) then (
                        prog.asm (LEA (Index (RCX, RAX), Regst RDI)) "index";
                        prog.asm (MOV (Deref RDI, Regst RAX)) " +";
                    ) else (
                        prog.asm (MOV (Index (RCX, RAX), Regst RAX)) "index";
                    )
                )
                | S_SHL | S_SHR -> (
                    gen_expr envt tags Value rhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, va_depth) tags Value lhs;
                    retrieve depth RCX;
                    (if op = S_SHL
                        then prog.asm (SHL (Regst CL, Regst RAX)) ""
                        else prog.asm (SHR (Regst CL, Regst RAX)) ""
                    );
                )
                | S_AND | S_OR | S_XOR -> (
                    gen_expr envt tags Value rhs;
                    store depth RAX;
                    gen_expr (depth+1, frame, va_depth) tags Value lhs;
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
            gen_expr envt tags Value rhs;
            store depth RAX;
            gen_expr (depth+1, frame, va_depth) tags Value lhs;
            retrieve depth RCX;
            prog.asm (CMP (Regst RCX, Regst RAX)) "compare";
            let tagbase = sprintf "%d_cmp" (label_id ()) in
            let (jump_instr, case_nojump, comment) = (match op with
                | C_LT -> (JLT (label, tagbase), 0, "case <")
                | C_LE -> (JLE (label, tagbase), 0, "case <=")
                | C_EQ -> (JEQ (label, tagbase), 0, "case ==")
                | C_GT -> (JLE (label, tagbase), 1, "case ! >")
                | C_GE -> (JLT (label, tagbase), 1, "case ! >=")
                | C_NE -> (JEQ (label, tagbase), 1, "case ! ==")
            ) in
            prog.asm jump_instr comment;
            prog.asm (MOV (Const case_nojump, Regst RAX)) " +";
            prog.asm (JMP (label, tagbase ^ "_done")) " +";
            prog.asm (TAG (label, tagbase)) " +";
            prog.asm (MOV (Const (1-case_nojump), Regst RAX)) " +";
            prog.asm (TAG (label, tagbase ^ "_done")) " +";
        )
        | EIF (cond, expr_true, expr_false) -> (
            let tagbase = sprintf "%d_tern" (label_id ()) in
            gen_expr envt tags Value cond;
            prog.asm (TST (Regst RAX, Regst RAX)) "apply ternary";
            prog.asm (JEQ (label, tagbase ^ "_false")) "";
            gen_expr envt tags Value expr_true;
            prog.asm (JMP (label, tagbase ^ "_done")) "end case true";
            prog.asm (TAG (label, tagbase ^ "_false")) "begin case false";
            gen_expr envt tags Value expr_false;
            prog.asm (TAG (label, tagbase ^ "_done")) "end ternary";
        )
        | ESEQ exprs -> List.iter (gen_expr envt tags Value) exprs
    in
    let rec get_global_vars = function
        | [] -> []
        | (CFUN ((_, name), _, _)) :: tl -> (name, FnPtr name) :: (get_global_vars tl)
        | (CDECL ((loc, name), initval)) :: tl -> (
            (match initval with
                | None -> prog.int name 0;
                | Some v -> (
                    match Reduce.redexp ~force:true consts v with
                        | _, CST c -> prog.int name c;
                        | _, STRING s -> (
                            let tag = prog.str s in
                            prog.quad name tag
                        )
                        | _ -> (
                            Error.error (Some loc) "initialisation of global variables must be a compile-time constant";
                            prog.int name 0;
                        )
                )
            );
            (name, (Globl name)) :: (get_global_vars tl)
        )
    in
    (match find_duplicate_decl extract_decl_id decl_list with
        | None -> ()
        | Some (loc, name) -> Error.error (Some loc) (sprintf "redefinition of %s" name)
    );
    let global = get_global_vars decl_list in
    let fmt_int = prog.exc "Unhandled exception %s(%d)\n" in
    let fmt_str = prog.exc "Unhandled exception %s(\"%s\")\n" in
    let defined = List.map (fun (name, _) -> (name, FnPtr name)) stdlib in
    List.iter (gen_decl (global::defined::universal::[])) decl_list;
    (    (* hand-compiled emergency exception handler: prints exception name and parameter as int *)
        prog.asm (FUN handler) "handle uncaught exceptions";
        prog.asm NOP " -> exception name is in %rdi";
        prog.asm NOP " -> exception parameter is in %rax";
        (* flush stdout *)
        prog.asm (MOV (Regst RAX, Regst RBX)) "save parameter";
        prog.asm (MOV (Regst RDI, Regst R12)) "save name";
        prog.asm (MOV (Globl "stdout", Regst RDI)) "1st arg is stdout";
        prog.asm (CAL "fflush") "flush output before error";
        (* print error *)
        prog.asm (MOV (Regst RBX, Regst RCX)) "4th arg is parameter";
        prog.asm (MOV (Regst R12, Regst RDX)) "3rd arg is name";
        (* see if exception parameter is a global string *)
        prog.asm (LEA (Globl ".str_start", Regst RAX)) "first string";
        prog.asm (CMP (Regst RCX, Regst RAX)) "";
        prog.asm (JGT (handler, "int")) "not a string";
        prog.asm (LEA (Globl ".str_end", Regst RAX)) "last string";
        prog.asm (CMP (Regst RCX, Regst RAX)) "";
        prog.asm (JLE (handler, "int")) "not a string";
        prog.asm (LEA (Globl fmt_str, Regst RSI)) "2nd arg is format";
        prog.asm (JMP (handler, "str")) "";
        (* continue normally *)
        prog.asm (TAG (handler, "int")) "parameter is an integer";
        prog.asm (LEA (Globl fmt_int, Regst RSI)) "2nd arg is format";
        prog.asm (TAG (handler, "str")) "parameter was a string";
        prog.asm (MOV (Globl "stderr", Regst RDI)) "1st arg is stderr";
        prog.asm (XOR (Regst RAX, Regst RAX)) "no args in vector registers";
        prog.asm (CAL "fprintf") "";
        (* exit *)
        prog.asm (MOV (Const 111, Regst RDI)) "value";
        prog.asm (MOV (Const 60, Regst RAX)) "code for exit";
        prog.asm SYS "";
    );
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
