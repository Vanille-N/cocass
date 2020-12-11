def expect(*args):
    return (1, "", "Assertion failure at {}.c:5\n".format(args[0][2:]))

data = [
    [],
]
