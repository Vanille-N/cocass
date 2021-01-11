from subprocess import Popen, PIPE

def verify(cmd):
    proc = Popen(cmd, stdout=PIPE, stdin=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    status = True
    if err != b'':
        print("Expected empty stderr")
        status = False
    if out != b'This goes to stdout.\n':
        print("Wrong stdout: [{}]".format(out))
        status = False
    if proc.returncode != 0:
        print("Nonzero exit code")
        status = False
    with open("dump.log", 'r') as f:
        s = f.read()
    if s != "This goes to the log.\n":
        print("Wrong file contents: [{}]".format(s))
        status = False
    return status

cfg = [
    [],
]
