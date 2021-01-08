type mon_op = M_MINUS | M_NOT | M_POST_INC | M_POST_DEC | M_PRE_INC | M_PRE_DEC
    | M_DEREF | M_ADDR
   (** Unary operators
     * M_MINUS: opposite -e of e;
     * M_NOT: bitwise negation ~e of e;
     * M_POST_INC: post-increment e++;
     * M_POST_DEC: post-decrement e--;
     * M_PRE_INC: pre-increment ++e;
     * M_PRE_DEC: pre-decrement --e.
     * M_DEREF: dereference *e;
     * M_ADDR: indirection &e;
     *)

type bin_op = S_MUL | S_DIV | S_MOD | S_ADD | S_SUB | S_INDEX
    | S_SHL | S_SHR | S_AND | S_OR | S_XOR
   (** Binary operators
     * S_MUL: integer multiplication;
     * S_DIV: integer division (quotient);
     * S_MOD: integer division (remainder);
     * S_ADD: integer addition;
     * S_SUB: integer subtraction;
     * S_INDEX: array access a[i].
     * S_SHL: left shift
     * S_SHR: right shift
     * S_AND: bitwise and
     * S_OR: bitwise inclusive or
     * S_XOR: bitwise exclusive or
     *)

type cmp_op = C_LT | C_LE | C_EQ
    | C_GT | C_GE | C_NE
   (** Comparaison operators:
     * C_LT (less than): <;
     * C_LE (less than or equal to): <=;
     * C_EQ (equal): ==.
     * C_GT (greater than): >;
     * C_GE (greater than or equal to): >=;
     * C_NE (not equal): !=;
     *)

type loc_expr = Error.locator * expr
and expr =
  | VAR of string (** a variable --- always of type int *)
  | CST of int (** an integer constant *)
  | STRING of string (** a string constant *)
  | SET of loc_expr * loc_expr (** assignment x = e *)
  | OPSET of bin_op * loc_expr * loc_expr (** assignment x ?= e --- ? one of *,+,-,/,%,|,& *)
  | CALL of string * loc_expr list (** function call f(e1,...,en) *)
  | OP1 of mon_op * loc_expr
    (** OP1(mop, e) is any unary operation *)
  | OP2 of bin_op * loc_expr * loc_expr
    (** OP2(bop,e,e') is any binary operation *)
  | CMP of cmp_op * loc_expr * loc_expr
    (** CMP(cop,e,e') is any comparison *)
  | EIF of loc_expr * loc_expr * loc_expr
    (** EIF(e1,e2,e3) is e1?e2:e3 --- also used for logical negation: !e is parsed as EIF(e, 0, 1) *)
  | ESEQ of loc_expr list
    (** e1, ..., en expression sequence *)

type top_declaration =
  | CDECL of var_declaration * loc_expr option
    (** global integer variable, possibly with an initialization value *)
  | CFUN of var_declaration * var_declaration list * loc_code
    (** function declaration with arguments and body *)
and var_declaration = Error.locator * string
and local_declaration = var_declaration * loc_expr option
and loc_code = Error.locator * code
and code =
    | CBLOCK of loc_code list (** { code; } *)
    | CLOCAL of local_declaration list
    | CEXPR of loc_expr (** an expression e; executed as an instruction *)
    | CIF of loc_expr * loc_code * loc_code (** if (e) c1; else c2; *)
    | CWHILE of loc_expr * loc_code * loc_expr * bool (** test_at_start? while (e) c; finally; *)
    | CRETURN of loc_expr option (** return; ou return (e); *)
    | CBREAK
    | CCONTINUE
    | CSWITCH of loc_expr * (Error.locator * int * loc_code) list * loc_code
    | CTRY of loc_code * catch list * loc_code
    | CTHROW of string * loc_expr
and catch = Error.locator * string * string * loc_code (** loc, exception name, variable binding, handler code *)

val cline : int ref
val ccol : int ref
val oldcline : int ref
val oldccol : int ref
val cfile : string ref

val getloc : unit -> string * int * int * int * int

val loc_of_expr : Error.locator*'a -> Error.locator
val e_of_expr : loc_expr -> expr
