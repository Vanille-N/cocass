from subprocess import Popen, PIPE

def verify(cmd):
    proc = Popen(cmd, stdout=PIPE, stdin=PIPE, stderr=PIPE)
    cproc = Popen(["ls", "-l"], stdout=PIPE, stdin=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    cout, cerr = cproc.communicate()
    status = True
    if proc.returncode != cproc.returncode:
        print("Wrong return code: [{}]; expect[{}]".format(proc.returncode, cproc.returncode))
        status = False
    if err != cerr:
        print("Wrong error:\n      [{}]\nexpect[{}]".format(err, cerr))
        status = False
    if out != cout + b'[pere] le fils a termine !\n':
        print("Wrong output")
        print(out)
        status = False
    return status

cfg = [
    [],
]
