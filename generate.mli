(** A few used registers (not a complete list) *)
type register =
    | RAX
    | RBX
    | RCX | CL
    | RDX
    | RDI
    | RSI
    | RSP
    | RBP
    | R08
    | R09
    | R10
    | R11
    | R12
    | RIP

(** Any way to refer to an assembler variable / value *)
type location =
    | Stack of int (** a variable on the stack *)
    | Const of int (** a constant value *)
    | Globl of string (** a global variable *)
    | FnPtr of string (** a function tag *)
    | Hexdc of string (** a hexadecimal constant *)
    | Regst of register (** a register *)
    | Deref of register (** a register read as an address *)
    | Index of register * register (** an array access *)

(** A single assembler instruction.
  * This is _not_ meant to be a full assembler, but a subset of the available instructions
  * useful for our purposes.
  *)
type instruction =
    | RET (** return *)
    | QTO (** convert qword RAX to oword RDX:RAX *)
    | LTQ (** convert dword EAX to qword RAX *)
    | NOP
    | SYS (** syscall *)
    | CAL of string (** a function call *)
    | FUN of string (** a function declaration *)
    | INC of location (** increment *)
    | NOT of location (** unary bitwise not *)
    | NEG of location (** unary negation *)
    | DEC of location (** decrement *)
    | DIV of location (** signed division *)
    | MUL of location (** signed multiplication *)
    | PSH of location (** push to the stack *)
    | POP of location (** pop from the stack *)
    | TAG of string * string (** declare function.label *)
    | JMP of string * string (** jump to function.label *)
    | JLE of string * string (** jump to function.label if less or equal *)
    | JLT of string * string (** jump to function.label if less *)
    | JGE of string * string (** jump to function.label if greater or equal *)
    | JGT of string * string (** jump to function.label if greater *)
    | JEQ of string * string (** jump to function.label if equal *)
    | JNE of string * string (** jump to function.label if not equal *)
    | MOV of location * location (** move qword *)
    | LEA of location * location (** load address *)
    | SUB of location * location (** subtraction *)
    | ADD of location * location (** addition *)
    | XOR of location * location (** binary bitwise excl. or *)
    | SHL of location * location (** left arithmetic shift *)
    | SHR of location * location (** right arithmetic shift *)
    | AND of location * location (** binary bitwise and *)
    | IOR of location * location (** binary bitwise incl. or *)
    | CMP of location * location (** compare *)
    | TST of location * location (** calc flags for binary bitwise and, used for cmp to zero *)

(** a list of global declarations and assembler instructions *)
type program = {
    int: string -> int -> unit; (** declare a global integer variable *)
    quad: string -> string -> unit; (** a global integer variable initialized with a string descriptor *)
    str: string -> string; (** declare a (possibly new) global string *)
    exc: string -> string; (** declare a (possibly new) exception *)
    asm: instruction -> string -> unit; (** add a new instruction *)
    gen: (out_channel * bool) -> unit; (** dump formatted assembler *)
}

(** empty program *)
val make_prog: unit -> program
