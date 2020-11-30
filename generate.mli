type register =
    | RAX
    | RBX
    | RCX | CL
    | RDX
    | RDI
    | RSI
    | RSP
    | RBP
    | R8
    | R9
    | R10

type location =
    | Stack of int
    | Glob of string
    | Reg of register
    | Deref of register
    | Const of int
    | Index of register * register
    | FnPtr of string

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
    | XOR of location * location
    | SHL of location * location
    | SHR of location * location
    | AND of location * location
    | OR of location * location
    | MUL of location
    | PUSH of location
    | POP of location
    | NOP
    | CMP of location * location
    | TEST of location * location
    | JLE of string * string
    | JLT of string * string
    | JEQ of string * string

type program

val decl_int: program -> string -> unit
val decl_str: program -> string -> string -> unit
val decl_asm: program -> instruction -> string -> unit

val make_prog: unit -> program

val generate: out_channel -> program -> unit
