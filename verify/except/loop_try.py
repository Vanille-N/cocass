def verify(*args):
    res = ""
    for i in range(12):
        res += "i = {}\n".format(i)
        if i == 3:
            res += "Found 3\n"
        if i != 7:
            res += "Always except 7 ({}).\n".format(i)
    return (0, res + "Loop exited at 11.\n", "")

data = [
    [],
]
