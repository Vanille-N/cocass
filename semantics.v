Require Import ZArith String.
Require Import List.
Open Scope Z_scope.
Open Scope string_scope.

(* Definitions of ±C expressions *)

Inductive mon_op : Type :=
  | M_MINUS | M_NOT | M_POST_INC
  | M_POST_DEC | M_PRE_INC | M_PRE_DEC | M_DEREF | M_ADDR.
Inductive bin_op : Type :=
  |  S_MUL | S_DIV | S_MOD | S_ADD
  | S_SUB | S_INDEX | S_SHL | S_SHR | S_AND | S_OR | S_XOR.
Inductive cmp_op : Type := C_LT | C_LE | C_EQ | C_GT | C_GE | C_NE.

Inductive expr : Type :=
  | VAR (x:string)
  | CST (n:Z)
  | STRING (s:string)
  | SET_VAR (s:string) (e:expr)
  | SET_ARRAY (t:string) (e:expr) (e':expr)
  | SET_DEREF (lhs:expr) (rhs:expr)
  | OPSET_VAR (op:bin_op) (x:string) (e:expr)
  | OPSET_ARRAY (op:bin_op) (x:string) (i:expr) (e:expr)
  | OPSET_DEREF (op:bin_op) (a:expr) (e:expr)
  | CALL (f:string) (args:list expr)
  | OP1 (op:mon_op) (e:expr)
  | OP2 (op:bin_op) (lhs:expr) (rhs:expr)
  | CMP (op:cmp_op) (lhs:expr) (rhs:expr)
  | EIF (cnd:expr) (e1:expr) (e0:expr)
  | ESEQ (es:list expr).

Inductive var_decl : Type :=
  | VDECL (name:string) (init:option expr).

Inductive code : Type :=
  | CBLOCK (cs:list code)
  | CLOCAL (vs:list var_decl)
  | CEXPR (e:expr)
  | CIF (cnd:expr) (c1 c0 : code)
  | CWHILE (cnd:expr) (body:code) (fin:option expr) (tst:bool)
  | CRETURN (e:option expr)
  | CBREAK
  | CCONTINUE
  | CSWITCH (e:expr) (cases:list (Z * list code)) (default:code)
  | CTRY (body:code) (catches:list catch) (fin:option code)
  | CTHROW (exc:string) (val:expr)
with catch : Type :=
  | CATCH (exc bind : string) (handle:code).

Inductive toplevel_decl : Type :=
  | CDECL (name:string) (init:option expr)
  | CFUN (name:string) (args:list var_decl) (body:code).

(* A memory model *)

Definition memory : Set := list (Z * Z).

Definition uint_max := Zpower_nat 2 64 - 1.
Definition int_max := Zpower_nat 2 63 - 1.
Definition int_min := - Zpower_nat 2 63.

Definition signed_to_unsigned_64 (n:Z) := if Z.gtb n 0 then n else (Zpower_nat 2 64 + n + 1).
Definition unsigned_to_signed_64 (n:Z) := if Z.gtb n int_max then (n - Zpower_nat 2 64) else n.

Lemma unsigned_inverse : forall n, n >= 0 /\ n <= uint_max -> signed_to_unsigned_64 (unsigned_to_signed_64 n) = n.
Proof.
    intros.
    destruct (Z.gtb n 0).
    - auto.
    - auto.
Qed.

Compute (signed_to_unsigned_64 (-1)).

Fixpoint rd_raw (m:memory) (a:Z) :=
    match m with
        | nil => 0
        | (loc,val) :: rest => if Z.eqb loc a then val else (rd_raw rest a)
    end.

Fixpoint rd_bytes (m:memory) (a:Z) (i:nat) :=
    match i with
        | O => 0
        | S p => (rd_bytes m (a+1) p) * 256 + (rd_raw m a)
    end.

Definition rd_int (m:memory) (a:Z) := unsigned_to_signed_64 (rd_bytes m a 8).
Variable rd_str : memory -> Z -> string.

Definition wr_raw (m:memory) (a:Z) (v:Z) := (a,v) :: m.
(* Write bytes into memory *)
Fixpoint wr_bytes (m:memory) (a:Z) (v:Z) (i:nat) :=
    match i with
        | O => m
        | S p => wr_bytes (wr_raw m a (v mod 256)) (a+1) (v / 256) p
    end.
Definition wr_int (m:memory) (a:Z) (v:Z) := wr_bytes m (signed_to_unsigned_64 a) v 8.
Inductive flag : Type :=
  | brk | ret | cnt | nil | Exc (e:string).

Definition state : Set := (scope * memory * flag * Z).

Inductive eval_expr : state -> expr -> state -> Prop :=
  | var : forall rho mu v x, eval_expr (rho,mu,nil,v) (VAR x) (rho,mu,nil,mu.(rd_int) (rho x))
  | var_chi : forall rho mu chi v x, chi <> nil
    -> eval_expr (rho,mu,chi,v) (VAR x) (rho,mu,chi,v)
  | cst : forall rho mu v n, eval_expr (rho,mu,nil,v) (CST n) (rho,mu,nil,n)
  | cst_chi : forall rho mu chi v n, chi <> nil
    -> eval_expr (rho,mu,chi,v) (CST n) (rho,mu,chi,v)
  | str : forall rho mu v s a, mu.(rd_str) a = s
    -> eval_expr (rho,mu,nil,v) (STRING s) (rho,mu,nil,a)
  | str_chi : forall rho mu chi v s, chi <> nil
    -> eval_expr (rho,mu,chi,v) (STRING s) (rho,mu,chi,v)
  | idx : forall rho mu chi v i mu_i chi_i v_i a mu' v_a,
    eval_expr (rho,mu,chi,v) i (rho,mu_i,chi_i,v_i)
    /\ eval_expr (rho,mu_i,chi_i,v_i) a (rho,mu',nil,v_a)
    -> eval_expr (rho,mu,chi,v) (OP2 S_INDEX a i) (rho,mu',nil,mu'.(rd_int) (v_a + v_i * 8)).




Lemma one : forall rho mu v, eval_expr (rho,mu,nil,v) (CST 1) (rho,mu,nil,1).
Proof.
  intros; apply cst.
Qed.
