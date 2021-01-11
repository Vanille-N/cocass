from subprocess import Popen, PIPE

def verify(cmd, size):
    proc = Popen([cmd, str(size)], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    status = True
    if proc.returncode != 0:
        print("Wrong return code: [{}]; expect[0]".format(proc.returncode))
        status = False
    if err != b'':
        print("Expected no stderr, got [{}]".format(err))
    lst, srt = out.decode('utf-8').rstrip().split("\n")
    lst = [int(s) for s in lst.rstrip().split(' ')]
    srt = [int(s) for s in srt.rstrip().split(' ')]
    lst.sort()
    if lst != srt:
        print("Output does not match")
        if len(lst) != len(srt):
            print("Not the same size: [{}]; expect[{}]".format(len(lst), len(srt)))
        for i in range(len(lst)):
            if lst[i] != srt[i]:
                print("Values differ at position {}: [{}]; expect[{}]".format(i, lst[i], srt[i]))
        status = False
    return status

cfg = [
    [1],
    [10],
    [100],
    [1000],
    [5000],
]
