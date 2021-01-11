from subprocess import Popen, PIPE

def expect(*args):
    proc = Popen(["bash", "-c", "cat Makefile | wc"], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    return (0, out.decode('utf-8'), "")

data = [
    [],
]
