def expect(*args):
    ret = ""
    for i in range(1, 9):
        ret += "x{} = {}\n".format(i, i)
    return (0, ret, "")

data = [
    [],
]
