#!/usr/bin/python

from subprocess import run
import sys

assets = ["fact", "ordre"]

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

