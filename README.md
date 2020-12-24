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
