def expect(*args):
    n = int(args[1])
    if n == 0:
        return (111, "", "Unhandled exception Zero(\"Hello, World\")\n")
    elif n == 1:
        return (111, "", "Unhandled exception One(\"foo\")\n")
    elif n == 2:
        return (111, "", "Unhandled exception Two(\"bar\")\n")
    else:
        return (0, "", "")


data = [
    ["-1"],
    ["0"],
    ["1"],
    ["2"],
]
