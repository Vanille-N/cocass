def verify(*args):
    res = ""
    for i in range(8):
        if i != 5:
            res += "i = {}\n".format(i)
    return (0, res, "Unhandled exception Exit(0)\n")

data = [
    [],
]
