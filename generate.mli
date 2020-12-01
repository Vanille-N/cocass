(** A few used registers (not a complete list) *)
type register =
    | RAX
    | RCX | CL
    | RDX
    | RDI
    | RSI
    | RSP
    | RBP
    | R08
    | R09
    | R10
    | RIP

(** Any way to refer to an assembler variable / value *)
type location =
    | Stack of int (** a variable on the stack *)
    | Const of int (** a constant value *)
    | Globl of string (** a global variable *)
    | FnPtr of string (** a function tag *)
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
    | TST of location * location (** calc flags for binary bitwise and, used for cmp to zero*)

(** a list of global declarations and assembler instructions *)
type program

(** declare a global integer variable *)
val decl_int: program -> string -> unit

(** declare a global string *)
val decl_str: program -> string -> string -> unit

(** add a new instruction *)
val decl_asm: program -> instruction -> string -> unit

(** empty program *)
val make_prog: unit -> program

(** dump formatted assembler *)
val generate: (out_channel * bool) -> program -> unit
