#!/usr/bin/python

from subprocess import run
import sys

assets = [
    ("easy", [[], ["-O"]],
        "ex0", "ex1", "ex2", "add",
        "ret", "scoped_ret", "isdigit",
    ),
    ("call", [[], ["-O"]],
        "argcount", "noreturn", "multicall",
        "has_args", "hello", "argsort", "call",
        "exit", "put", "printglob", "cat",
        "sprintf", "quine",
    ),
    ("calc", [[], ["-O"]],
        "fact", "binops", "bitwise", "cmp",
        "ordre", "incdec", "cmp_order", "shifts",
        "calc",
    ),
    ("ptr", [[], ["-O"]],
        "array", "string", "fnptr", "additions",
        "extended_assign", "multifnptr",

    ),
    ("flow", [[], ["-O"]],
        "break", "continue", "count", "loops",
        "switch_loop",
    ),
    ("reduce", [[], ["-O"]],
        "reduce_eif", "reduce_monops", "reduce_binops",
        "reduce_cmp", "big_switch",
    ),
    ("except", [[], ["-O"]],
        "exc1", "exc2", "exc3", "except",
        "loop_try", "try_loop",
        "try_switch", "any_catch",
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
    for d in module.data:
        prog = "./assets/{}".format(fbase)
        res = run([prog, *d], capture_output=True)
        code, out, err = res.returncode, res.stdout, res.stderr
        (expect_code, expect_out, expect_err) = module.verify(prog, *d)
        expect_out, expect_err = bytes(expect_out, 'UTF-8'), bytes(expect_err, 'UTF-8')
        if expect_code == code and expect_err == err and expect_out == out:
            print("    \x1b[32m[OK]\x1b[0m {}".format(d))
        else:
            print("    \x1b[31m[KO]\x1b[0m {}".format(d))
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


def fulltest(cc, fbase, more=[]):
    print("Checking {}:".format(fbase))
    if compile(cc, fbase, more=more):
        check(fbase)
        return True
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

    if len(args) >= 1:
        for fbase in args:
            if len(fbase) >= 2 and fbase[0:2] == "--":
                for (category, more_args, *tests) in assets:
                    if category == fbase[2:]:
                        for fbase in tests:
                            for more in more_args:
                                fulltest(cc, category + '/' + fbase, more=more)
            else:
                fulltest(cc, fbase)
                fulltest(cc, fbase, more=['-O'])
    else:
        for (category, more_args, *tests) in assets:
            print("\n\n    <<< category: {} >>>\n".format(category))
            for fbase in tests:
                for more in more_args:
                    fulltest(cc, category + '/' + fbase, more=more)

main()
