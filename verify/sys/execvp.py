from subprocess import Popen, PIPE

def verify(cmd, *args):
    proc = Popen([cmd, *args], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    cproc = Popen(args, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    cout, cerr = cproc.communicate()
    status = True
    if cout != out:
        print("Wrong output:\n      [{}]\nexpect[{}]".format(out, cout))
        status = False
    if cerr != err:
        print("Wrong error:\n       [{}]\nexpect[{}]".format(err, cerr))
        status = False
    if proc.returncode != cproc.returncode:
        print("Wrong return code: [{}]; expect[{}]".format(proc.returncode, cproc.returncode))
        status = False
    return status

cfg = [
    ["ls", "-la"],
    ["cat", "Makefile", "compile.ml"],
    ["bash", "-c", "exit 1"],
    ["wc", "-wl", "compile.ml"],
]
