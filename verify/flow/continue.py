def expect(*args):
    res = ""
    for i in range(10):
        if (i == 5): continue
        res += "{} ".format(i)
    res += '\n'
    for i in range(10):
        if (i == 7 or i == 3):
            res += '\n'
            continue
        for j in range(10):
            if (i == j):
                res += "     "
                continue
            res += "({},{}) ".format(i, j)
        res += '\n'
    return (0, res, "")

data = [
    [],
]
