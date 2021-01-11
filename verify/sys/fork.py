from subprocess import Popen, PIPE

def verify(cmd):
    proc = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    expected = [b'I am parent\nI am child\n', b'I am child\nI am parent\n']
    status = True
    if out not in expected:
        print("Wrong output:\n       [{}] is not one of the expected results".format(out))
        status = False
    if err != b'':
        print("Wrong error:\n       [{}]\nexpect[{}]".format(err, ''))
        status = False
    if proc.returncode != 0:
        print("Wrong return code: [{}]; expect[{}]".format(proc.returncode, 0))
        status = False
    return status

cfg = [
    [],
]
