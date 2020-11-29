open Printf

type register = AX | BX | CX | DX | DI | SI | SP | BP | R8 | R9

type location =
    | Stack of int
    | Glob of string
    | Reg of register
    | Deref of register
    | Const of int
    | Index of register * register

type instruction =
    | RET
    | CQTO
    | CLTQ
    | SYS
    | CALL of string
    | FUN of string
    | TAG of string * string
    | INC of location
    | NOT of location
    | NEG of location
    | DEC of location
    | DIV of location
    | JMP of string * string
    | MOV of location * location
    | LEA of location * location
    | SUB of location * location
    | ADD of location * location
    | MUL of location
    | PUSH of location
    | POP of location
    | NOP
    | CMP of location * location
    | JLE of string * string
    | JLT of string * string
    | JEQ of string * string

type program = {
    mutable idata: string list;
    mutable sdata: (string * string) list;
    mutable text: (instruction * string) list;
}

let decl_int prog name =
    prog.idata <- name :: prog.idata

let decl_str prog name value =
    prog.sdata <- (name, value) :: prog.sdata

let decl_asm prog instr info =
    prog.text <- (instr, info) :: prog.text

let make_prog () =
    {
        idata = [];
        sdata = [];
        text = [];
    }

let regname = function
    | AX -> "ax"
    | BX -> "bx"
    | CX -> "cx"
    | DX -> "dx"
    | DI -> "di"
    | SI -> "si"
    | SP -> "sp"
    | BP -> "bp"
    | R8 -> "8"
    | R9 -> "9"

type alignment =
    | TextRt of string
    | TextLt of string
    | Node of alignment list
    | Skip of int

let locate = function
    | Stack k -> [TextRt (sprintf "%d(%%rbp" k); TextLt ")"]
    | Glob v -> [TextRt (sprintf "%s(%%rip" v); TextLt ")"]
    | Reg r -> [TextRt (sprintf "%%r%s" (regname r)); Skip 1]
    | Deref r -> [TextRt (sprintf "(%%r%s" (regname r)); TextLt ")"]
    | Const c -> [TextRt (sprintf "$%d" c); Skip 1]
    | Index (addr, idx) -> [TextLt (sprintf "(%%r%s,%%r%s,8)" (regname addr) (regname idx)); Skip 1]

let lpad n s =
    let pad = String.make (max 0 (n - String.length s)) ' ' in
    pad ^ s

let generate_ialign name =
    [TextLt (name ^ ": "); TextLt ".zero 8"]

let generate_salign (name, value) =
    [TextLt (name ^ ": "); TextLt (sprintf ".string \"%s\"" (String.escaped value))]

let generate_talign (instr, info) =
    let fmtinfo = TextLt (
        (if info = "" then "#" else "# " ^ info)
        ^ (if instr = RET then "\n" else "")
    ) in
    match instr with
        | RET -> [TextLt "    ret "; Skip 5; fmtinfo]
        | CQTO -> [TextLt "    cqto "; Skip 5; fmtinfo]
        | CLTQ -> [TextLt "    cltq "; Skip 5; fmtinfo]
        | SYS -> [TextLt "    syscall "; Skip 5; fmtinfo]
        | CALL fn -> [TextLt "    call "; TextLt fn; Skip 4; fmtinfo]
        | FUN fn -> [TextLt (fn ^ ":"); Skip 5; fmtinfo]
        | TAG (fn, tag) -> [TextLt (sprintf "  %s.%s:" fn tag); Skip 5; fmtinfo]
        | INC l -> [TextLt "    incq "; Node (locate l); Skip 3; fmtinfo]
        | NOT l -> [TextLt "    not "; Node (locate l); Skip 3; fmtinfo]
        | NEG l -> [TextLt "    neg "; Node (locate l); Skip 3; fmtinfo]
        | DEC l -> [TextLt "    decq "; Node (locate l); Skip 3; fmtinfo]
        | DIV l -> [TextLt "    idiv "; Node (locate l); Skip 3; fmtinfo]
        | JMP (fn, tag) -> [TextLt "    jmp "; TextLt (sprintf "%s.%s" fn tag); Skip 4; fmtinfo]
        | SUB (s, d) -> [TextLt "    sub "; Node (locate s); TextLt ", "; Node (locate d); fmtinfo]
        | ADD (s, d) -> [TextLt "    add "; Node (locate s); TextLt ", "; Node (locate d); fmtinfo]
        | MOV (s, d) -> [TextLt "    mov "; Node (locate s); TextLt ", "; Node (locate d); fmtinfo]
        | LEA (s, d) -> [TextLt "    lea "; Node (locate s); TextLt ", "; Node (locate d); fmtinfo]
        | MUL l -> [TextLt "    mul "; Node (locate l); Skip 3; fmtinfo]
        | PUSH l -> [TextLt "    push "; Node (locate l); Skip 3; fmtinfo]
        | POP l -> [TextLt "    pop "; Node (locate l); Skip 3; fmtinfo]
        | NOP -> if info = ""
            then [TextLt "    nop "; Skip 5; fmtinfo]
            else [Skip 6; fmtinfo]
        | CMP (a, b) -> [ TextLt "    cmp "; Node (locate a); TextLt ", "; Node (locate b); fmtinfo]
        | JLE (fn, tag) -> [ TextLt "    jle "; TextLt (sprintf "%s.%s" fn tag); Skip 4; fmtinfo]
        | JLT (fn, tag) -> [ TextLt "    jl "; TextLt (sprintf "%s.%s" fn tag); Skip 4; fmtinfo]
        | JEQ (fn, tag) -> [ TextLt "    je "; TextLt (sprintf "%s.%s" fn tag); Skip 4; fmtinfo]

let display_align out marks text =
    (* printf "newline\n"; *)
    let current = ref 0 in
    let target = ref 0 in
    let marks = ref marks in
    let pop lst =
        let x = List.hd !lst in
        lst := List.tl !lst;
        x
    in
    let rec aux = function
        | TextRt t -> (
            let len = String.length t in
            target := !target + pop marks;
            let unused = max 0 (!target - !current - len) in
            fprintf out "%s%s" (String.make unused ' ') t;
            current := len + unused + !current;
        )
        | TextLt t -> (
            let len = String.length t in
            target := !target + pop marks;
            let unused = max 0 (!target - !current - len) in
            fprintf out "%s%s" t (String.make unused ' ');
            current := len + unused + !current;
        )
        | Node l -> List.iter aux l
        | Skip k -> for i = 1 to k do aux (TextLt "") done
    in List.iter aux text;
    fprintf out "\n"

let generate (out:out_channel) prog =
    fprintf out "    .data\n";
    fprintf out "    .align 8\n";
    let idata = List.rev prog.idata in
    let ialign = List.map generate_ialign idata in
    List.iter (display_align out [10; 0]) ialign;
    let sdata = List.rev prog.sdata in
    let salign = List.map generate_salign sdata in
    List.iter (display_align out [10; 0]) salign;
    fprintf out "\n";
    fprintf out "    .global main\n";
    fprintf out "    .text\n";
    let tdata = List.rev prog.text in
    let talign = List.map generate_talign tdata in
    List.iter (display_align out [9; 12; 0; 0; 12; 7; 0]) talign;
