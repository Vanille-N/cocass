def expect(*args):
    cnt = 0
    res = ""
    for i in range(5):
        for j in range(6):
            res += "{} ".format(cnt)
            cnt += 1
        res += '\n'
    return (0, res, "")

data = [
    [],
]
