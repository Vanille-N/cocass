type register =
    | RAX
    | RBX | BL
    | RCX | CL
    | RDX | DL
    | RDI
    | RSI
    | RSP
    | RBP
    | R08
    | R09
    | R10
    | RIP

type location =
    | Stack of int
    | Const of int
    | Globl of string
    | FnPtr of string
    | Regst of register
    | Deref of register
    | Index of register * register

type instruction =
    | RET
    | QTO
    | LTQ
    | SYS
    | NOP
    | CAL of string
    | FUN of string
    | INC of location
    | NOT of location
    | NEG of location
    | DEC of location
    | DIV of location
    | MUL of location
    | PSH of location
    | POP of location
    | TAG of string * string
    | JMP of string * string
    | JLE of string * string
    | JLT of string * string
    | JEQ of string * string
    | MOV of location * location
    | LEA of location * location
    | SUB of location * location
    | ADD of location * location
    | XOR of location * location
    | SHL of location * location
    | SHR of location * location
    | AND of location * location
    | IOR of location * location
    | CMP of location * location
    | TST of location * location

type program

val decl_int: program -> string -> unit
val decl_str: program -> string -> string -> unit
val decl_asm: program -> instruction -> string -> unit

val make_prog: unit -> program

val generate: (out_channel * bool) -> program -> unit
