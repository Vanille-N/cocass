def expect(*args):
    l = [int(i) for i in args[1:]]
    res = "min = {}\nmax = {}\n".format(min(l), max(l))
    return (0, res, "")

data = [
    "0".split(),
    "1 2 8 3 9".split(),
    "41 589 -12 -56 0 1 500".split(),
    "1 8 9 -1".split(),
    "10 9 8".split(),
    "8 9 10".split(),
]
