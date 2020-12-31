# COCass

Neven Villani, ENS Paris-Saclay

## Build

Make targets:
- `make` builds `mcc`
- `make test` runs `mcc` on the tests: test files in `assets/`, verifiers in `verify/`. Each test is a `.c` file and a `.py` verifier, the output of the compiled executable is checked against the verifier for each set of command line arguments.

Note: `make test` executes `./test.py`, which you can also invoke directly:
`./test.py [TESTS]` where `TESTS` is a list of
- `category/` (e.g. `except/`) to run a full category of tests
- `file` (e.g. `except/exc1`) to run a single test

or is left empty to run all tests.


## Usage

`mcc [OPTIONS] [FILE]`

Where options are:
- `-D` print declarations and exit
- `-A` print AST and exit
- `-S` dump assembler and exit
- `-v`, `-v1` report structural items
- `-v2` report details
- `--no-reduce` disables reduction of expressions whose result is known at compile-time
    (added because reduction was required for toplevel initialisation, and I decided to make it available for all expressions. Nevertheless having the ability to turn it on and off is useful for verification)
- `--no-color` turn off syntax highlighting
    (added because I wanted to add color, but still needed the option of turning it off if the terminal doesn't support it or in order to pipe the output to a file)

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

### Unary operators

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
### Binary operators and comparisons

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

### Extended assignment
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

### Control flow
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

### Declarations
```ocaml
CLOCAL
    Examples
        int x;       -> CLOCAL[("x", None)]
        int x, y;    -> CLOCAL[("x", None), ("y", None)]
        int x = 1;   -> CLOCAL[("x", Some (CST 1))]
```

### Switch
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

### Try
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

```ocaml
expr
    SET_VAR (name, value), SET_ARRAY (name, idx, value) -> SET (loc, val)
code
    CBLOCK (locals, body) -> CBLOCK (body)
    CWHILE (cond, body) -> CWHILE (cond, body, finally, check)
var_declaration
```
### Assignments
```ocaml
SET
    Code
        x = 1;
        t[0] = 1;
    Old
        SET_VAR("x", CST 1)
        SET_ARRAY("t", CST 0, CST 1)
    New
        SET (VAR "x", CST 1)
        SET (OP2 (S_INDEX, VAR "t", CST 1))
```
Justification:
With the addition of `*x`, `SET_DEREF (x, e)` was first added but required much code duplication.
Also, `t[x][y] = 1;` was a parsing error, but `t[x][y]` was a valid expression.
Since `M_DEREF` added the (ugly) workaround `*&t[x][y] = 1`, I decided it was time to allow more expressions to be treated as lvalues. Changing assignment was deemed the best course of action.
At the same time, formerly `OPSET_VAR`, `OPSET_ARRAY` and `OPSET_DEREF` became `OPSET`.

### Blocks
```ocaml
CBLOCK
    Code
        {
            int x;
            x = 1;
        }
    Old
        CBLOCK (CDECL "x", [CEXPR (SET_VAR ("x", CST 1))])
    New
        CBLOCK [
            CLOCAL ("x", None);
            CEXPR (SET (VAR "x", CST 1))
        ]
```
Justification:
As soon as `int x;` and `int x = 1;` were allowed anywhere in the code, it made no more sense to have blocks carry information on the variables defined inside of them.

### Loops
```ocaml
CWHILE
    Code
        for (e1; e2; e3) { c }
        while (e) { c }
        do { c } while (e);
    Old
        e1; CWHILE (e2, c @ [e3])
        CWHILE (e, c)
        error
    New
        e1; CWHILE (e2, c, e3, true)
        CWHILE (e, c, ESEQ [], true)
        CWHILE (e, c, ESEQ [], false)
```
Justification:
The addition of `do-while` required some information on whether the test should be done at the start of the loop, a boolean was chosen.
At the same time, wanting to implement `break` and `continue`, it was deemed necessary to separate the body block and the finally clause of `for`. This is what the third argument accomplishes.
