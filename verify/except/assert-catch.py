def expect(*args):
    i = int(args[1])
    j = int(args[2])
    if i != j:
        return (0, "{} is not equal to {}\n".format(i, j), "")
    else:
        return (0, "", "")

data = [
    ["0", "1"],
    ["0", "0"],
    ["1524", "12"],
    ["85696", "85696"],
]
