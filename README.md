# COCass

Neven Villani, ENS Paris-Saclay

## Build

Make targets:
- `make` builds `mcc`
- `make test` runs `mcc` on the tests: test files in `assets/`, verifiers in `verify/`. Each test is a `.c` file and a `.py` verifier, the output of the compiled executable is checked against the verifier for each set of command line arguments.

## Usage

`mcc [OPTIONS] [FILE]`

Where options are:
- `-D` print declarations and exit
- `-A` print AST and exit
- `-S` dump assembler and exit
- `-v`, `-v1` report structural items
- `-v2` report details
- `-O` enables reduction of expressions whose result is known at compile-time
- `--no-color` turn off syntax highlighting (if your terminal doesn't support it or if you want to pipe the output to a file)

## Requirements

`cpp` for the preprocessing, `gcc` for the linking.

## Structure

```
─┐
 ├─ assets
 │  ├─ calc/*.c      arithmetic tests
 │  ├─ call/*.c      function call tests
 │  ├─ decl/*.c      variable declaration tests
 │  ├─ easy/*.c      bootstrapping tests
 │  ├─ except/*.c    exception tests
 │  ├─ flow/*.c      control flow tests
 │  ├─ misc/*.c      tests that are difficult to automate
 │  ├─ ptr/*.c       array access and dereferences
 │  ├─ reduce/*.c    optimization tests
 │  └─ string/*.c    char* manipulation
 ├─ failures/*.c     files that are expected to be rejected or issue a warning
 ├─ verify/*/*.py    Python verifiers
 ├─ cAST.ml          syntax tree builder
 ├─ clex.mll         lexer
 ├─ compile.ml       AST -> simplified assembler
 ├─ cparse.mly       source -> AST
 ├─ cprint.ml        AST pretty-print
 ├─ error.ml         error reporting
 ├─ generate.ml      simplified assembler -> asm source code
 ├─ genlab.ml        (unused)
 ├─ main.ml          argument parsing
 ├─ pigment.ml       color abstraction
 ├─ reduce.ml        ASM simplifier
 ├─ test.py          automatic tester
 ├─ verbose.ml       verbosity control
 └─ *.mli
```

## Extensions

Constructors that were added
```ocaml
mon_op
    M_DEREF                (* dereference *)
    M_ADDR                 (* indirection *)
bin_op
    S_SHL, S_SHR           (* bit shifts *)
    S_AND, S_OR, S_XOR     (* bitwise operators *)
cmp_op
    C_GT, C_GE, C_NE       (* comparisons *)
expr
    OPSET (op, var, e)     (* extended assignment var <- var op e *)
code
    CBREAK, CCONTINUE      (* control flow keywords *)
    CLOCAL (decls)         (* variable declaration *)
    CSWITCH (e, cases, default)   (* selection statement *)
    CTRY (body, handlers, finally)   (* exception handling block *)
    CTHROW (exc, e)      (* raise exception exc(e) *)
```
Examples

```ocaml
M_DEREF
    Examples
        *x          -> OP1(M_DEREF, VAR "x")
        *(x+1)      -> OP1(M_DEREF, OP2(S_ADD, VAR "x", CST 1))
```
```ocaml
M_ADDR
    Examples
        &x         -> OP1(M_ADDR, VAR "x")
        &x[10]     -> OP1(M_ADDR, OP2(M_INDEX, VAR "x", CST 10))
        &*x        -> OP1(M_ADDR, OP1(M_DEREF, VAR "x"))
    Errors
        &10
        &(x+1)
        &"abc"     -> Indirection needs an lvalue

```
```ocaml
S_SHL, S_SHR, S_OR, S_XOR, S_AND
    Examples
        x << 2     -> OP2(S_SHL, VAR "x", CST 2)
        x >> 2     -> OP2(S_SHR, VAR "x", CST 2)
        x | 2      -> OP2(S_OR, VAR "x", CST 2)
        x ^ 2      -> OP2(S_XOR, VAR "x", CST 2)
        x & 2      -> OP2(S_AND, VAR "x", CST 2)
```
```ocaml
C_GT, C_GE, C_NE
    Reduction
        EIF(CMP(C_EQ, a, b), 0, 1) -> CMP(C_NE, a, b)
        EIF(CMP(C_LE, a, b), 0, 1) -> CMP(C_GT, a, b)
        EIF(CMP(C_LT, a, b), 0, 1) -> CMP(C_GE, a, b)
```
```ocaml
OPSET
    Examples
        x += 2     -> OPSET(M_ADD, VAR "x", CST 2)
        x *= 2     -> OPSET(M_MUL, VAR "x", CST 2)
        etc...
    Errors
        x []= 2    -> parsing error
        2 += 2     -> Extended assignment needs an lvalue
```
```ocaml
CBREAK, CCONTINUE, CTHROW
    Examples
        break;       -> CBREAK
        continue;    -> CCONTINUE
        throw E(x);  -> CTHROW("E", VAR "x")
        throw E;     -> CTHROW("E", VAR "NULL")
    Errors
        try { break; }  -> break may not reach outside of try
        try { continue; }  -> continue may not reach outside of try
```
```ocaml
CLOCAL
    Examples
        int x;       -> CLOCAL[("x", None)]
        int x, y;    -> CLOCAL[("x", None), ("y", None)]
        int x = 1;   -> CLOCAL[("x", Some (CST 1))]
```
```ocaml
CSWITCH
    Examples
        switch (x) {
            case 1:
            case 2:
            default:
        }
        -> CSWITCH (VAR x, [
             (1, CBLOCK []);
             (2, CBLOCK [])
           ], CBLOCK [])
```
```ocaml
CTRY
    Examples
        try {
        } catch (E x) {
        } catch (F _) {
        } catch (G) {
        } finally {
        }
        -> CTRY (CBLOCK [], [
             ("E", "x", CBLOCK []);
             ("F", "_", CBLOCK []);
             ("G", "_", CBLOCK [])
           ], CBLOCK [])
```


## Modifications

Constructors that were changed
```ocaml
expr
    SET_VAR (name, value), SET_ARRAY (name, idx, value) -> SET (loc, val)
var_declaration
    CDECL (loc, name) -> CDECL (loc, name, init_val)
code
    CBLOCK (locals, body) -> CBLOCK (body)
    CWHILE (cond, body) -> CWHILE (cond, body, finally, check)
```
