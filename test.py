#!/usr/bin/python

from subprocess import run
import sys

assets = [
    "ex0", "ex1", "ex2", "add", "ret",  # trivial
    "argcount", "noreturn", "multicall", # arguments and function calls
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

def check(fbase):
    module = Module("assets/{}.py".format(fbase))
    for d in module.data:
        res = run(["./assets/{}".format(fbase), *d], capture_output=True)
        code, out, err = res.returncode, res.stdout, res.stderr
        (expect_code, expect_out, expect_err) = module.verify(*d)
        expect_out, expect_err = bytes(expect_out, 'UTF-8'), bytes(expect_err, 'UTF-8')
        if expect_code == code and expect_err == err and expect_out == out:
            print("    \x1b[32m[OK]\x1b[0m {}".format(d))
        else:
            print("    \x1b[31m[KO]\x1b[0m {}".format(d))
            if expect_code != code:
                print("        \x1b[33mWrong code: \x1b[32m[{}] \x1b[31m[{}]\x1b[0m".format(expect_code, code))
            if expect_out != out:
                print("        \x1b[33mWrong stdout: \x1b[32m[{}] \x1b[31m[{}]\x1b[0m".format(expect_out, out))
            if expect_err != err:
                print("        \x1b[33mWrong stderr: \x1b[32m[{}] \x1b[31m[{}]\x1b[0m".format(expect_err, err))


def fulltest(cc, fbase, more=[]):
    print("Running {}:".format(fbase))
    if compile(cc, fbase, more):
        check(fbase)
        return True
    return False

def main():
    if len(sys.argv) >= 2:
        cc = sys.argv[1]
        if cc == "gcc":
            more = lambda fbase: ["-o", "assets/{}".format(fbase)]
        elif cc == "clang":
            more = lambda fbase: ["-o", "assets/{}".format(fbase)]
        elif cc == "mcc":
            cc = "./mcc"
            more = lambda x: []
        else:
            more = lambda x: []
    else:
        cc = "./mcc"
        more = lambda x: []
    if len(sys.argv) >= 3:
        bases = sys.argv[2:]
    else:
        bases = assets
    for fbase in bases:
        fulltest(cc, fbase, more=more(fbase))

main()
