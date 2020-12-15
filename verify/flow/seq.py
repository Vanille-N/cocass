def expect(*args):
    res = ""
    res += "1 2\n"
    for i in range(10):
        res += "{} {}\n".format(i, -i)
    return (0, res, "")

data = [
    [],
]
