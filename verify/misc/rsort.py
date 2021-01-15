from subprocess import Popen, PIPE
import random as rnd

def verify(cmd, size, maxi):
    proc = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    data = "{} ".format(size)
    numbers = [rnd.randint(0, maxi) for i in range(size)]
    data += " ".join(str(i) for i in numbers)
    out, err = proc.communicate(data.encode('utf-8'))
    ret = proc.returncode
    status = True
    if ret != 0:
        print("Nonzero return code: {}".format(ret))
        status = False
    if err != b'':
        print("Non-empty stderr: '{}'".format(err))
        status = False
    out = out.decode('utf-8').rstrip().split('\n')
    if out[0] != "Enter array size: Enter {} elements:".format(size):
        print("Wrong header '{}'".format(out[0]))
        status = False
    if out[1] != " ".join(str(i) for i in numbers) + ' ':
        print("Error reading numbers")
        status = False
    if out[2] != "Now sorting":
        print("Wrong announcement")
        status = False
    if out[3] != "Done!":
        print("Did not announce sort")
        status = False
    if out[4] != " ".join(str(i) for i in sorted(numbers)):
        print("Did not sort properly")
        status = False
    return status

cfg = [
    [10, 10],
    [100, 10],
    [10, 100],
    [100, 100],
    [1000, 1],
    [1000, 10],
    [1000, 100],
    [1000, 1000],
]
