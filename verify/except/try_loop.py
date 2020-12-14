def expect(*args):
    res = ""
    for i in range(8):
        if i != 5:
            res += "i = {}\n".format(i)
    return (111, res, "Unhandled exception Exit(0)\n")

data = [
    [],
]
