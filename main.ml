open CAST
open Verbose
open Compile
open Arg

let input = ref stdin
let c_prefix = ref "a.out"
let c_D = ref false
let c_A = ref false
let c_C = ref false
let c_S = ref false

let basename s =
    try String.sub s 0 (String.rindex s '.')
    with Not_found -> s

let () =
    parse
        [("-v",  Unit (fun () -> verbose:=1), "reports stuff");
         ("-v1", Unit (fun () -> verbose:=1), "reports stuff");
         ("-v2", Unit (fun () -> verbose:=2), "reports stuff, and stuff");
         ("-D",  Unit (fun () -> c_D:=true),  "print declarations");
         ("-A",  Unit (fun () -> c_A:=true),  "print abstract syntax tree");
         ("-C",  Unit (fun () -> c_C:=true),  "print abstract syntax tree close to the C code");
         ("-S",  Unit (fun () -> c_S:=true),  "output assembler dump")]
        (fun s ->
            c_prefix := basename s;
            input :=
                Unix.open_process_in ("cpp -DMCC \"" ^ (String.escaped s) ^ "\""))
        "compiles a C-- program"

let () =
    let lexbuf = Lexing.from_channel (!input) in
    let c = Cparse.translation_unit Clex.ctoken lexbuf in
    let out = if !c_S then stdout else open_out (!c_prefix ^ ".s") in
    Error.flush_error ();

    if !c_D then (
        Cprint.print_declarations Format.std_formatter c
    );
    if !c_A then (
        Cprint.print_ast Format.std_formatter c
    );
    if !c_C then (
        Cprint.print_ast_close_to_C Format.std_formatter c
    );

    if not (!c_D || !c_A || !c_C) then (
        compile out c;
        Error.flush_error ()
    );

    if not (!c_D || !c_A || !c_C || !c_S) then (
        flush out;
        close_out_noerr out;
        let command =
            let prefix = String.escaped !c_prefix in
            Printf.sprintf
                "gcc -ggdb -o \"%s\" \"%s.s\" -lc -lm"
                prefix prefix
        in
        ignore (Unix.system command)
    )
