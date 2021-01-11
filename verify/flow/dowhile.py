from subprocess import Popen, PIPE
from random import randint

def verify(cmd, nb_iter):
    proc = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    data = []
    for i in range(nb_iter):
        data.append(randint(0, 50))
    data = [str(i) for i in data] + ["-1"]
    out, err = proc.communicate(input=bytes('\n'.join(data) + '\n', 'utf-8'))
    expected = bytes(''.join(["I got {}\n".format(i) for i in data] + ["Ended after -1\n"]), 'utf-8')
    status = True
    if expected != out:
        print("Wrong output:\n      [{}]\nexpect[{}]".format(expected, out))
        status = False
    if err != b'':
        print("Wrong error:\n       [{}]\nexpect[{}]".format(err, ''))
        status = False
    if proc.returncode != 0:
        print("Wrong return code: [{}]; expect[{}]".format(proc.returncode, 0))
        status = False
    return status

cfg = [
    [0],
    [10],
    [50],
    [1000],
]
