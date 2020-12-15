def expect(*args):
    return (111, "", "Unhandled exception AssertionFailure(\"{}.c:5\")\n".format(args[0][2:]))

data = [
    [],
]
