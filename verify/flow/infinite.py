def expect(*args):
    line = "".join("{} ".format(i) for i in range(10))
    return (0, (line + '\n') * 2, "")

data = [
    [],
]
