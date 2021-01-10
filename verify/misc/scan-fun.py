from subprocess import Popen, PIPE

def verify(cmd, param):
    proc = Popen(cmd, stdin=PIPE, stdout=PIPE)
    out, err = proc.communicate(input=bytes("{}\n".format(param), 'utf-8'))
    expected = bytes("You gave me the number {}".format(param), 'utf-8')
    if expected != out:
        print("Wrong output:\n      [{}]\n   != [{}]".format(expected, out))
    return True

cfg = [
    [15],
    [-1],
    [0],
    [50666584],
]
