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
    (* | JEQ of location * location *)
    (* | JGE of location * location *)
    (* | JGT of location * location *)
    (* | JLE of location * location *)
    (* | JLT of location * location *)
    (* | JNE of location * location *)
    (* | IDX of location * location * location *)

type program

val decl_int: program -> string -> unit
val decl_str: program -> string -> string -> unit
val decl_asm: program -> instruction -> string -> unit

val make_prog: unit -> program

val generate: Format.formatter -> program -> unit