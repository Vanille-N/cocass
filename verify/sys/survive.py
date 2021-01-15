from subprocess import Popen, PIPE, signal
import time as t

def verify(cmd, iter):
    proc = Popen(cmd, stdout=PIPE, stderr=PIPE)
    for i in range(iter):
        t.sleep(0.05)
        proc.send_signal(signal.SIGINT);
    t.sleep(0.05)
    proc.send_signal(signal.SIGTERM);
    t.sleep(0.05)
    out = proc.stdout.read().decode('utf-8').rstrip().split("\n")
    err = proc.stderr.read()
    status = True
    if err != b'':
        print("Non-empty stderr '{}'".format(err))
        status = False
    if "I am " not in out[0]:
        print("Wrong header")
        status = False
    if len(out) != iter + 1:
        print("Too few messages")
        status = False
    for x in out[1:]:
        if x != "You can't kill me !":
            print("Wrong text '{}'".format(x))
            status = False
    return status

cfg = [
    [0],
    [1],
    [2],
    [5],
]
