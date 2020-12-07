def verify(*args):
    res = ""
    for i in range(1000):
        for j in range(5):
            res += "{} ".format(i << j)
            res += "{} ".format(i >> j)
        res += '\n'
    return (0, res, "")

data = [
    [],
]
