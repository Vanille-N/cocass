def mean(arr):
    if arr == []: return 0
    return sum(arr) // len(arr)

def expect(*args):
    i = 1
    n = len(args)
    count = 0
    total = 0
    while i < n:
        if '-w' in args[i]:
            weight = int(args[i][2:])
            i += 1
        else:
            weight = 1
        item = int(args[i])
        count += weight
        total += item * weight
        i += 1
    if count == 0: return (0, "0\n", "")
    return (0, "{}\n".format(total // count), "")

data = [
    [],
    ["10"],
    "-w3 10 20".split(),
    "1 10 -w10 100 1000".split(),
    "5 7 9 -w2 3 5 1 8 2 -w3 9 3 5 1 2 -w2 7 8 4 5 -w9 6 9 9 3 2".split(),
    "-w1000 20 0".split(),
    "-w0 50 10".split(),
    "-w0 10".split(),
]
