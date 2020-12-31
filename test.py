#!/usr/bin/python

from subprocess import run
import sys

assets = [
    ("easy", [["--no-reduce"], []],
        "ex0", "ex1", "ex2", "add",
        "ret", "scoped_ret", "isdigit",
        "ex3", "ex4", "ex5", "ex6", "ex7",
        "ex8", "ex9", "ex10", "ex11", "ex12",
    ),
    ("call", [["--no-reduce"], []],
        "argcount", "noreturn", "multicall",
        "has_args", "hello", "call",
        "exit", "printglob", "max",
        "varargs", "assert",
    ),
    ("calc", [["--no-reduce"], []],
        "fact", "binops", "bitwise", "cmp",
        "ordre", "incdec", "cmp_order", "shifts",
        "calc",
    ),
    ("ptr", [["--no-reduce"], []],
        "array", "fnptr", "additions",
        "extended_assign", "multifnptr",
        "addr-deref", "dbl-array",
    ),
    ("string", [["--no-reduce"], []],
        "argsort", "cat", "path", "put",
        "quine", "sprintf", "string", "strret",
    ),
    ("flow", [["--no-reduce"], []],
        "break", "continue", "count", "loops",
        "switch_loop", "seq",
    ),
    ("reduce", [["--no-reduce"], []],
        "reduce_eif", "reduce_monops", "reduce_binops",
        "reduce_cmp", "big_switch", "single_step",
        "array",
    ),
    ("except", [["--no-reduce"], []],
        "exc1", "exc2", "exc3", "except",
        "loop_try", "try_loop",
        "try_switch", "any_catch",
        "nothrow", "uncaught-str",
        "assert-catch",
    ),
    ("decl", [["--no-reduce"], []],
        "init", "alternate", "typedef",
        "ptr", "scope-switch", "override",
        "string",
    ),
]

class Module:
    def __init__(self, path, **kwargs):
        d = kwargs
        exec(open(path).read(), d)
        # d.pop("__builtins__")
        for k in d.keys():
            instr = "self.{elem} = d['{elem}']".format(elem=k)
            exec(instr)

def compile(cc, fbase, more=[]):
    print("  compile: {} assets/{}.c {}".format(cc, fbase, "".join(more)))
    res = run([cc, "assets/{}.c".format(fbase), *more], capture_output=True)
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
    prog = "./assets/{}".format(fbase)
    for d in module.data:
        res = run([prog, *d], capture_output=True)
        code, out, err = res.returncode, res.stdout, res.stderr
        (expect_code, expect_out, expect_err) = module.expect(prog, *d)
        expect_out, expect_err = bytes(expect_out, 'UTF-8'), bytes(expect_err, 'UTF-8')
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
    return (ok, ko)


def fulltest(cc, fbase, more=[]):
    print("Checking {}:".format(fbase))
    if compile(cc, fbase, more=more):
        ok, ko = check(fbase)
        return (ok, ko)
    else:
        exit(100)
    return False

def main():
    if len(sys.argv) == 2:
        if sys.argv[1] == "help":
            print("Automated tester for a C-- compiler")
            print("  usage:")
            print("      test file [file2, ...]")
            print("              check the compiled output by mcc")
            print("              of assets/file.c against the specification in verify/file.py")
            print("      test --category")
            print("              execute check for all tests from the given category")
            print("      test")
            print("              execute all checks")
            print("      test help")
            print("              print this help")
            print("      test categ")
            print("              print all categories")
            print("      test list")
            print("              print all files")
            return
        elif sys.argv[1] == "categ":
            for (category, *tests) in assets:
                print(category)
            return
        elif sys.argv[1] == "list":
            for (category, *tests) in assets:
                print("{}: {}".format(category, ", ".join(tests)))
            return

    cc = "./mcc"
    args = sys.argv[1:]

    nb_files = 0
    nb_tests = 0
    nb_error = 0

    if len(args) >= 1:
        for fbase in args:
            if len(fbase) >= 1 and fbase[-1] == "/":
                for (category, more_args, *tests) in assets:
                    if category == fbase[:-1]:
                        for fbase in tests:
                            nb_files += 1
                            for more in more_args:
                                ok, ko = fulltest(cc, category + '/' + fbase, more=more)
                                nb_error += ko
                                nb_tests += ok
            else:
                nb_files += 1
                ok, ko = fulltest(cc, fbase)
                nb_error += ko
                nb_tests += ok
                ok, ko = fulltest(cc, fbase, more=['-O'])
                nb_error += ko
                nb_tests += ok
    else:
        for (category, more_args, *tests) in assets:
            print("\n\n    <<< category: {} >>>\n".format(category))
            for fbase in tests:
                nb_files += 1
                for more in more_args:
                    ok, ko = fulltest(cc, category + '/' + fbase, more=more)
                    nb_tests += ok
                    nb_error += ko
    print()
    print("Ran {} successful tests on {} test files".format(nb_tests, nb_files))
    print("{} errors".format(nb_error))

main()
