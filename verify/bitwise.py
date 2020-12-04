def bit_and(x, y):
    return "{} & {} = {}\n".format(x, y, x & y)

def bit_or(x, y):
    return "{} | {} = {}\n".format(x, y, x | y)

def bit_xor(x, y):
    return "{} ^ {} = {}\n".format(x, y, x ^ y)

def bit_not(x):
    return "~{} = {}\n".format(x, ~x)

def verify(*args):
    ret = ""
    for i in range(200):
        for j in range(i, 200):
            ret += bit_and(i, j)
            ret += bit_or(i, j)
            ret += bit_xor(i, j)
        ret += bit_not(i)
    return (0, ret, "")

data = [
    [],
]
