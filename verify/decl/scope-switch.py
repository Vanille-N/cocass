def expect(*args):
    x = int(args[1])
    if x == 0:
        return (0, "1\n", "")
    elif 1 <= x <= 4:
        return (0, "2\n", "")
    else:
        return (0, "", "")

data = [
    ["0"],
    ["1"],
    ["2"],
    ["3"],
    ["4"],
    ["5"],
    ["6"],
]
