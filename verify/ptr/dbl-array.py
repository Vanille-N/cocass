def expect(*args):
    arr = [[2*i + j + 1 for j in range(2)] for i in range(3)]
    arr[0][0] += 1
    res = "".join(["[ {} ]\n".format(" ".join([str(n) for n in line])) for line in arr])
    return (0, res, "")

data = [
    [],
]
