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
