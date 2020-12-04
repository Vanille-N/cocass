def verify(args):
    j = 0
    i = 1
    res = ""
    fmtloop = "i = {}\n"
    fmtend = "i ended at {}\n\n"
    while (j != 10):
        res += fmtloop.format(i)
        res += "j = {}\n".format(j)
        j = i
        i += 1
    res += "j ended at {}\n".format(j)
    res += fmtend.format(i)
    for i in range(10):
        res += "i = {}\n".format(i)
    res += "i at 10\n\n"
    for i in range(15, -1, -1):
        res += fmtloop.format(i)
    res += fmtend.format(-1)
    i = -25;
    while (i != -3):
        i += 1
        res += fmtloop.format(i)
    i += 1
    res += fmtend.format(i)
    return (0, res, "")


data = [
    [],
]
