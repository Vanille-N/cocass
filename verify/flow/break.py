def expect(*args):
    res = ""
    for i in range(10):
        if i == 5: break
        res += "{} ".format(i)
    res += '\n'
    for i in range(10):
        if i == 7: break
        for j in range(10):
            if i == j: break;
            res += "({},{}) ".format(i, j)
        res += '\n'

    i = 0;
    while True:
        if i == 10:
            res += "exit.\n"
            break;
        res += "{} ".format(i)
        i += 1
    return (0, res, "")

data = [
    [],
]
