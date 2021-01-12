def expect(*args):
    res = ""
    res += "a = 5\n"
    res += "b = 10\n"
    res += "a = 10\n"
    res += "b = 5\n"
    return (0, res, "")

data = [
    [],
]
