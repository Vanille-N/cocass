from subprocess import Popen, PIPE
import time as t

def verify(cmd):
    start = t.time()
    proc = Popen(cmd, stdout=PIPE, stdin=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    end = t.time()
    status = True
    if end - start < 0.9:
        print("Process exited too quickly")
        status = False
    if err != b'':
        print("Did not expect any stderr")
        status = False
    if proc.returncode != 0:
        print("Expected return code 0")
        status = false
    return status

cfg = [
    [],
]
