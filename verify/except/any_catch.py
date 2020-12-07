def verify(*args):
    i = int(args[1])
    if i == 0:
        return (0, "Zero\nExit.\n", "")
    elif i == 1 or i == 2:
        return (0, "Something else\nExit.\n", "")
    else:
        return (0, "Exit.\n", "")

data = [
    ["0"],
    ["1"],
    ["2"],
    ["3"],
]
