# COCass

Neven Villani, ENS Paris-Saclay

## Build

Make targets:
- `make` builds `mcc`
- `make test` runs `mcc` on the tests: test files in `assets/`, verifiers in `verify/`. Each test is a `.c` file and a `.py` verifier, the output of the compiled executable is checked against the verifier for each set of command line arguments.

Note: `make test` executes `./check.py`, which you can also invoke directly:
`./check.py [TESTS]` where `TESTS` is a list of
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
 │  ├─ boot/*.c      tests to get started
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
