def expect(*argv):
    res = ""
    argc = len(argv)
    if argc > 2:
        res += "I have at least two args: {}, {}\n".format(argv[1], argv[2])
        if (argc > 3):
            res += "I even have one more: {}\n".format(argv[3])
        else:
            res += "...nevermind, I have only two.\n"
    elif argc > 1:
        res += "I have just a single argument: {}\n".format(argv[1])
    else:
        res += "I have no args other than my own name.\n"
    return (0, res, "")

data = [
    [],
    ["foo"],
    ["foo", "bar"],
    ["foo", "bar", "baz"],
    ["foo", "bar", "baz", "quux"],
]
