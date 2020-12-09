def foo(x1, x2, x3, x4, *rest):
    res = ""
    res += "1:{} 2:{} 3:{} 4:{}\n".format(x1, x2, x3, x4)
    for a in rest:
        if a != 0:
            res += "Next: {}\n".format(a)
    res += "Done.\n\n"
    return res

def bar(x1, x2, x3, x4, x5, x6, x7, x8, *rest):
    res = ""
    res += "1:{} 2:{} 3:{} 4:{}\n".format(x1, x2, x3, x4)
    res += "5:{} 6:{} 7:{} 8:{}\n".format(x5, x6, x7, x8)
    for a in rest:
        if a != 0:
            res += "Next: {}\n".format(a)
    res += "Done.\n\n"
    return res

def write(nb, *rest):
    res = ""
    for i in range(nb):
        res += "argument #{}: {}\n".format(i, rest[i])
    res += '\n'
    return res

def twice(nb, *rest):
    res = ""
    for i in range(nb):
        res += "two at once: {} {}\n".format(rest[i], rest[i])
    res += '\n'
    return res

def verify(*args):
    res = ""
    res += foo(1,2,3,4, 0)
    res += foo(*range(1,7), 0)
    res += foo(*range(1,13), 0)
    res += bar(*range(1,14), 0)
    res += write(2, 101,102)
    res += write(5, *range(101,106))
    res += write(15, *range(101,116))
    res += twice(5, 1,2,3,4,5)
    return (0, res, "")

data = [
    [],
]
