type mon_op = M_MINUS | M_NOT | M_POST_INC | M_POST_DEC | M_PRE_INC | M_PRE_DEC
    | M_DEREF | M_ADDR
   (** Les opérations unaires:
     * M_MINUS: calcule l'opposé -e de e;
     * M_NOT: calcule la négation logique ~e de e;
     * M_POST_INC: post-incrémentation e++;
     * M_POST_DEC: post-décrémentation e--;
     * M_PRE_INC: pré-incrémentation ++e;
     * M_PRE_DEC: pré-décrémentation --e.
     * M_DEREF: déférencement *e;
     * M_ADDR: indirection &e;
     *)

type bin_op = S_MUL | S_DIV | S_MOD | S_ADD | S_SUB | S_INDEX
    | S_SHL | S_SHR | S_AND | S_OR | S_XOR
   (** Les opérations binaires:
     * S_MUL: multiplication entière;
     * S_DIV: division entière (quotient);
     * S_MOD: division entière (reste);
     * S_ADD: addition entière;
     * S_SUB: soustraction entière;
     * S_INDEX: accès à un élément de tableau a[i].
     * S_SHL: shift gauche
     * S_SHR: shift droit
     * S_AND: et bit-à-bit
     * S_OR: ou incl. bit-à-bit
     * S_XOR: ou excl. bit-à-bit
     *)

type cmp_op = C_LT | C_LE | C_EQ
    | C_GT | C_GE | C_NE
   (** Les opérations de comparaison:
     * C_LT (less than): <;
     * C_LE (less than or equal to): <=;
     * C_EQ (equal): ==.
     * C_GT (greater than): >;
     * C_GE (greater than or equal to): >=;
     * C_NE (not equal): !=;
     *)

type loc_expr = Error.locator * expr
and expr =
  | VAR of string (** une variable --- toujours de type int. *)
  | CST of int (** une constante entiere. *)
  | STRING of string (** une constante chaine. *)
  | SET_VAR of string * loc_expr (** affectation x = e. *)
  | SET_ARRAY of string * loc_expr * loc_expr (** affectation x[e] = e. *)
  | SET_DEREF of loc_expr * loc_expr (** affectation *e = e. *)
  | OPSET_VAR of bin_op * string * loc_expr (** affectation x ?= e. *)
  | OPSET_ARRAY of bin_op * string * loc_expr * loc_expr (** affectation x[e] ?= e. *)
  | OPSET_DEREF of bin_op * loc_expr * loc_expr (** affectation *e ?= e. *)
  | CALL of string * loc_expr list (** appel de fonction f(e1,...,en) *)
  | OP1 of mon_op * loc_expr
    (** OP1(mop, e) dénote -e, ~e, e++, e--, ++e, ou --e. *)
  | OP2 of bin_op * loc_expr * loc_expr
    (** OP2(bop,e,e') dénote e*e', e/e', e%e',
                             e+e', e-e', ou e[e']. *)
  | CMP of cmp_op * loc_expr * loc_expr
    (** CMP(cop,e,e') vaut e<e', e<=e', ou e==e' *)
  | EIF of loc_expr * loc_expr * loc_expr
    (** EIF(e1,e2,e3) est e1?e2:e3 *)
  | ESEQ of loc_expr list
    (** e1, ..., en [sequence, analogue a e1;e2 au niveau code];
      si n=0, represente skip. *)

type var_declaration =
  | CDECL of Error.locator * string * loc_expr option
    (** declaration de variable de type int, possiblement avec une valeur d'initialisation. *)
  | CFUN of Error.locator * string * var_declaration list * loc_code
    (** fonction avec ses arguments, et son code. *)
and loc_code = Error.locator * code
and code =
    | CBLOCK of loc_code list (** { code; } *)
    | CLOCAL of var_declaration list
    | CEXPR of loc_expr (** une expression e; vue comme instruction. *)
    | CIF of loc_expr * loc_code * loc_code (** if (e) c1; else c2; *)
    | CWHILE of loc_expr * loc_code * (loc_expr option) * bool (** test_at_start? while (e) c; (finally;)*)
    | CRETURN of loc_expr option (** return; ou return (e); *)
    | CBREAK
    | CCONTINUE
    | CSWITCH of loc_expr * (Error.locator * int * loc_code) list * loc_code
    | CTRY of loc_code * catch list * loc_code option
    | CTHROW of string * loc_expr
and catch = Error.locator * string * string * loc_code

val cline : int ref
val ccol : int ref
val oldcline : int ref
val oldccol : int ref
val cfile : string ref

val getloc : unit -> string * int * int * int * int

val loc_of_expr : Error.locator*'a -> Error.locator
val e_of_expr : loc_expr -> expr
