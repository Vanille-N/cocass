from subprocess import Popen, PIPE

def verify(cmd, param):
    proc = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate(input=bytes("{}\n".format(param), 'utf-8'))
    expected = bytes("You gave me the number {}".format(param), 'utf-8')
    status = True
    if expected != out:
        print("Wrong output:\n      [{}]\nexpect[{}]".format(out, expected))
        status = False
    if err != b'':
        print("Wrong error:\n      [{}]\nexpect[{}]".format(err, b''))
        status = False
    if proc.returncode != 0:
        print("Wrong return code: [{}]; expect[{}]".format(proc.returncode, 0))
        status = False
    return status

cfg = [
    [15],
    [-1],
    [0],
    [50666584],
]
