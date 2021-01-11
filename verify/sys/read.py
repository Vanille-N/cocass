from subprocess import Popen, PIPE

def verify(cmd, data):
    proc = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate(bytes(data, 'utf-8'))
    status = True
    if proc.returncode != 0:
        print("Nonzero return code")
        status = False
    if err != b'':
        print("Expected empty stderr")
        status = False
    cmp = bytes("".join(data[i:i+3] + '\n' for i in range(0, len(data), 3)), 'utf-8')
    if out != cmp:
        print("Wrong split")
        print("        [{}]\n  expect[{}]".format(out, cmp))
        status = False
    return status

cfg = [
    ["..."],
    ["......"],
    ["foobarbazbaz"],
    ["AaaBbbCccDddEeeFffGgg"],
    [".?!.?!.?!.?!"],
    ["...................................................................................."],
]
