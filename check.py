#!/usr/bin/python3

from subprocess import run, Popen, PIPE
import sys

assets = [
    ("boot", [
        "ex0",
        "ex1",
        "ex2",
        "ex3",
        "ex4",
        "ex5",
        "ex6",
        "ex7",
        "ex8",
        "ex9",
        "ex10",
        "ex11",
        "ex12",
        "add",
        "ret",
        "scoped_ret",
        "isdigit",
    ]),
    ("call", [
        "hello",
        "has_args",
        "argcount",
        "max",
        "noreturn",
        "exit",
        "multicall",
        "call",
        "assert",
        "printglob",
        "bsearch",
        "varargs",
    ]),
    ("calc", [
        "cmp",
        "calc",
        "shifts",
        "binops",
        "bitwise",
        "incdec",
        "ordre",
        "minimax",
        "cmp_order",
        "syracuse",
        "mean",
        "wmean",
        "fact",
    ]),
    ("ptr", [
        "array",
        "swap",
        "dbl-array",
        "additions",
        "addr-deref",
        "extended_assign",
        "fnptr",
        "multifnptr",
    ]),
    ("string", [
        "put",
        "quine",
        "sprintf",
        "scan",
        "scan-fun",
        "string",
        "strret",
        "path",
        "argsort",
        "paren",
        "binconv",
        "cat",
        "memlib",
        "concise",
    ]),
    ("flow", [
        "loops",
        "count",
        "seq",
        "break",
        "continue",
        "switch_loop",
        "triangle",
        "dowhile",
        "infinite",
    ]),
    ("reduce", [
        "reduce_eif",
        "reduce_monops",
        "reduce_binops",
        "reduce_cmp",
        "big_switch",
        "single_step",
        "array",
    ]),
    ("except", [
        "exc1",
        "exc2",
        "exc3",
        "except",
        "loop_try",
        "try_loop",
        "try_switch",
        "any_catch",
        "nothrow",
        "uncaught-str",
        "assert-catch",
    ]),
    ("decl", [
        "init",
        "ptr",
        "typedef",
        "alternate",
        "scope-switch",
        "override",
        "string",
    ]),
    ("sys", [
        "fork",
        "execvp",
        "exec",
        "alarm",
        "dup-redir",
        "pipe-simple",
        "read",
    ]),
    ("misc", [
        "mwc",
        "sieve",
        "sort",
        "sudoku_solver",
    ]),
]

failures = [
    "arity",
    "assignment",
    "break_try",
    "break",
    "decl_alternate",
    "divzero",
    "duplicate_catch",
    "incompatible",
    "init_declaration",
    "invalid_va",
    "loop_try",
    "multidecl",
    "return_try",
    "switch",
    "undeclared",
]

class Module:
    def __init__(self, path, **kwargs):
        d = kwargs
        src = open(path).read()
        exec(src, d)
        # d.pop("__builtins__")
        for k in d.keys():
            instr = "self.{elem} = d['{elem}']".format(elem=k)
            exec(instr)

def compile(cc, fbase, more=[]):
    print("  compile: {} tests/{}.c {}".format(cc, fbase, "".join(more)))
    res = run([cc, "tests/{}.c".format(fbase), *more], stdout=PIPE, stderr=PIPE)
    success = True
    if res.returncode != 0:
        print("Errored: retcode {}".format(res.returncode))
        success = False
    for (data, stream) in zip([res.stderr, res.stdout], ["Err", "Out"]):
        if len(data) > 0:
            print("{} :: {}".format(stream, data.decode('UTF-8')))
    if len(res.stderr) > 0:
        success = False
    return success

def compare(lt, rt):
    if lt == rt:
        return None
    def context(s, pos, l):
        return s[max(0, pos-l) : min(len(s)+1, pos+l)]
    for i in range(max(len(lt), len(rt))):
        if i >= len(lt) or i >= len(rt) or lt[i] != rt[i]:
            return (i, context(lt, i, 10), context(rt, i, 10))

def check(fbase):
    module = Module("verify/{}.py".format(fbase))
    ok = 0
    ko = 0
    prog = "./tests/{}".format(fbase)
    try:
        _ = module.expect
        expect = True
    except AttributeError:
        expect = False
    if expect:
        for d in module.data:
            (expect_code, expect_out, expect_err) = module.expect(prog, *d)
            expect_out, expect_err = bytes(expect_out, 'UTF-8'), bytes(expect_err, 'UTF-8')
            res = run([prog, *d], stdout=PIPE, stderr=PIPE)
            code, out, err = res.returncode, res.stdout, res.stderr
            if expect_code == code and expect_err == err and expect_out == out:
                print("    \x1b[32m[OK]\x1b[0m {}".format(d))
                ok += 1
            else:
                print("    \x1b[31m[KO]\x1b[0m {}".format(d))
                ko += 1
                if expect_code != code:
                    print("        \x1b[33mWrong code:")
                    print("              \x1b[32m[{}]".format(expect_code))
                    print("              \x1b[31m[{}]\x1b[0m".format(code))
                diff = compare(expect_out, out)
                if diff is not None:
                    print("        \x1b[33mWrong stdout:")
                    print("              \x1b[32m[{}]".format(expect_out))
                    print("              \x1b[31m[{}]\x1b[0m".format(out))
                    print("        Difference at {}: [{}] vs [{}]".format(*diff))
                diff = compare(expect_err, err)
                if diff is not None:
                    print("        \x1b[33mWrong stderr:")
                    print("              \x1b[32m[{}]".format(expect_err))
                    print("              \x1b[31m[{}]\x1b[0m".format(err))
                    print("        Difference at {}: [{}] vs [{}]".format(*diff))
    else:
        for d in module.cfg:
            res = module.verify(prog, *d)
            if res:
                ok += 1
                print("    \x1b[32m[OK]\x1b[0m {}".format(d))
            else:
                ko += 1
                print("    \x1b[31m[KO]\x1b[0m {}".format(d))
    return (ok, ko)

def fulltest(cc, fbase, more=[]):
    try:
        with open("verify/{}.py".format(fbase)) as f:
            pass
    except FileNotFoundError:
        print("No such test: {}".format(fbase))
        exit(50)
    print("Checking {}:".format(fbase))
    if compile(cc, fbase, more=more):
        ok, ko = check(fbase)
        return (ok, ko)
    else:
        exit(100)
    return False

def verify_failure(cc, fbase):
    print("Checking {}".format(fbase))
    okE = koE = 0
    okW = koW = 0
    fname = "{}.c".format(fbase)
    print("  compile: {} {}".format(cc, fname))
    msg = run([cc, fname], stderr=PIPE, stdout=PIPE).stderr.decode('utf-8')
    fails = {}
    for l in msg.split('\n'):
        if "parser:" in l:
            ff, more = l.split(', line')
            loc, msg = more.split('): ')
            line = int(loc.split('(')[0])
            if "FATAL" in l:
                fails[(line, "err")] = [msg, False]
            else:
                fails[(line, "wrn")] = [msg, False]
    with open(fname, 'r') as f:
        for j,l in enumerate(f.readlines()):
            i = j + 1
            if '//!' in l:
                if (i, "err") in fails:
                    fails[(i, "err")][1] = True
                else:
                    print("    Expected an error at line {}".format(i))
                    koE += 1
            elif '//?' in l:
                if (i, "wrn") in fails:
                    fails[(i, "wrn")][1] = True
                else:
                    print("    Expected a warning at line {}".format(i))
                    koW += 1
    for key in fails:
        (line, type) = key
        msg, handled = fails[key]
        if handled:
            if type == "err":
                okE += 1
            else:
                okW += 1
        else:
            if type == "err":
                print("    Did not expect the error '{}' at line {}".format(msg, line))
                koE += 1
            else:
                print("    Did not expect the warning '{}' at line {}".format(msg, line))
                koW += 1
    if koE + koW == 0:
        print("    \x1b[32m[OK]\x1b[0m {}".format(fbase))
    else:
        print("    \x1b[31m[KO]\x1b[0m {}".format(fbase))
    return ((okW, koW), (okE, koE))

def main():
    if len(sys.argv) >= 2:
        if sys.argv[1] in ["--help", "-h"]:
            print("""Automated tester for a C-- compiler
      usage:
          check [TARGET ...]
              either:
                - compare the compiled output by mcc of tests/(TARGET).c
                  against the specification in verify/(TARGET).py
                  where TARGET is one of
                    CATEGORY/         a registered category
                    CATEGORY/FILE     a single file path
                - assert that all warnings and errors have been emitted
                  by scanning the source file for //! and //? comments
          check [-h|--help]
              print this help message
          check [-c|--categ]
              print all categories
          check [-l|--list] [CATEGORY ...]
              print all available files, only list those in certain categories
              if extra arguments are provided

      examples:
          check -l
          check -l sys ptr decl
          check sys/alarm string/ ptr/additions
          check failures/undeclared
    """)
            return
        elif sys.argv[1] in ["--categ", "-c"]:
            for (category, _) in assets:
                print(category)
            return
        elif sys.argv[1] in ["--list", "-l"]:
            categs = sys.argv[2:]
            for (category, tests) in assets:
                if categs == [] or category in categs:
                    print("{}: {}".format(category, ", ".join(tests)))
            return

    cc = "./mcc"
    args = sys.argv[1:]

    nb_files = nb_tests = nb_error = 0
    nb_okC = nb_koC = 0
    nb_okE = nb_koE = 0
    nb_okW = nb_koW = 0
    logs = []

    if len(args) >= 1:
        for fbase in args:
            if len(fbase) >= 1 and fbase[-1] == "/":
                if fbase[:-1] == "failures":
                    for f in failures:
                        nb_files += 1
                        wrn, err = verify_failure(cc, "failures/" + f)
                        logs.append((2, wrn, err))
                else:
                    for (category, tests) in assets:
                        if category == fbase[:-1]:
                            for fbase in tests:
                                nb_files += 1
                                for more in [["--no-reduce"], []]:
                                    ok, ko = fulltest(cc, category + '/' + fbase, more=more)
                                    logs.append((1, ok, ko))
            else:
                if "failures/" in fbase:
                    nb_files += 1
                    wrn, err = verify_failure(cc, fbase)
                    logs.append((2, wrn, err))
                else:
                    for more in [["--no-reduce"], []]:
                        nb_files += 1
                        ok, ko = fulltest(cc, fbase, more=more)
                        logs.append((1, ok, ko))
    else:
        for (category, tests) in assets:
            print("\n\n    <<< category: {} >>>\n".format(category))
            for fbase in tests:
                nb_files += 1
                for more in [["--no-reduce"], []]:
                    ok, ko = fulltest(cc, category + '/' + fbase, more=more)
                    logs.append((1, ok, ko))
        print("\n\n    <<< fail >>>\n")
        for f in failures:
            nb_files += 1
            wrn, err = verify_failure(cc, "failures/" + f)
            logs.append((2, wrn, err))

    for res in logs:
        if res[0] == 2:
            _, wrn, err = res
            okW, koW = wrn
            okE, koE = err
            nb_okE += okE
            nb_okW += okW
            nb_koE += koE
            nb_koW += koW
            nb_error += koE + koW
        else:
            _, ok, ko = res
            nb_error += ko
            nb_tests += ok
            nb_okC += ok
            nb_koC += ko

    print("\x1b[32m" if nb_error == 0 else "\x1b[31m")
    print("=====================================")
    print("Ran tests on {} files".format(nb_files))
    print("  {} failed tests".format(nb_error))
    print()
    print("  {} calculation checks, {} incorrect".format(nb_okC, nb_koC))
    print("  {} warning checks, {} incorrect".format(nb_okW, nb_koW))
    print("  {} error checks, {} incorrect".format(nb_okE, nb_koE))
    print("=====================================")
    print("\x1b[0m", end="")

main()
