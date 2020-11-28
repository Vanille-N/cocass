open Format

type register = AX | BX | CX | DX | DI | SI | SP | BP | R8 | R9

type location =
    | Stack of int
    | Glob of string
    | Reg of register
    | Deref of register

type instruction =
    | RET
    | QTO
    | CAL of string
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
    | MUL of location * location
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
