open Printf

type register = AX | BX | CX | DX | DI | SI | SP | BP | R8 | R9

type location =
    | Stack of int
    | Glob of string
    | Reg of register
    | Deref of register
    | Const of int

type instruction =
    | RET
    | CQTO
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

let address = function
    | Stack k -> sprintf "%d(%%rbp)" k
    | Glob v -> sprintf "%s(%%rip)" v
    | Reg r -> sprintf "%%r%s" (regname r)
    | Deref r -> sprintf "(%%r%s)" (regname r)
    | Const c -> sprintf "$%d" c

let generate_idata out name =
    fprintf out "%s: .long 0\n" name

let generate_sdata out name = ()

let generate_text out instr =
    let info = if snd instr = "" then "" else "    # " ^ (snd instr) in
    match fst instr with
        | RET -> fprintf out "    ret%s\n\n" info
        | CQTO -> fprintf out "    cqto%s\n" info
        | SYS -> fprintf out "    syscall%s\n" info
        | CALL fname -> fprintf out "    call %s%s\n" fname info
        | FUN fname -> fprintf out "%s:%s\n" fname info
        | TAG (fname, tagname) -> fprintf out "  %s.%s:%s\n" fname tagname info
        | INC loc -> fprintf out "    incq %s%s\n" (address loc) info
        | NOT loc -> fprintf out "    not %s%s\n" (address loc) info
        | NEG loc -> fprintf out "    neg %s%s\n" (address loc) info
        | DEC loc -> fprintf out "    decq %s%s\n" (address loc) info
        | DIV loc -> fprintf out "    idiv %s%s\n" (address loc) info
        | JMP (fname, tagname) -> fprintf out "    jmp %s.%s%s\n" fname tagname info
        | MOV (src, dest) -> fprintf out "    mov %s, %s%s\n" (address src) (address dest) info
        | LEA (src, dest) -> fprintf out "    lea %s, %s%s\n" (address src) (address dest) info
        | SUB (src, dest) -> fprintf out "    sub %s, %s%s\n" (address src) (address dest) info
        | ADD (src, dest) -> fprintf out "    add %s, %s%s\n" (address src) (address dest) info
        | MUL loc -> fprintf out "    mul %s%s\n" (address loc) info
        | PUSH loc -> fprintf out "    push %s%s\n" (address loc) info
        | POP loc -> fprintf out "    pop %s%s\n" (address loc) info
        | NOP -> fprintf out "%s\n" (if info = "" then "    nop" else info)

let generate (out:out_channel) prog =
    fprintf out "    .data\n";
    fprintf out "    .align 8\n";
    let idata = List.rev prog.idata in
    List.iter (generate_idata out) idata;
    let sdata = List.rev prog.sdata in
    List.iter (generate_sdata out) sdata;
    fprintf out "\n";
    fprintf out "    .global main\n";
    fprintf out "    .text\n";
    let text = List.rev prog.text in
    List.iter (generate_text out) text;
