def expect(*args):
    arr = [*range(10)]
    i = 0
    while (i < 10):
        arr[i] -= 1
        i += 1
    res = ""
    for i in range(10):
        res += "{}\n".format(arr[i])
    return (0, res, "")

data = [
    [],
]
