global i, j, k

def foo():
    return "foo: {} + {} -> {}\n".format(i, j, k[i + j])

def bar():
    ret = ""
    for i in zip([*range(0, 10),'A','B','C','D'], [*range(0, 13)]):
        ret += "{}:{}\n".format(*i)
    return ret

def baz(*x):
    ret = ""
    for i in zip([*range(0, 10),'A','B','C','D'], x):
        ret += "{}:{}\n".format(*i)
    return ret

def expect(*args):
    global i, j, k
    i = 0
    j = 0
    k = [1000] + [100 * i for i in range(1, 5)]
    ret = ""
    ret += foo()
    i += 1
    ret += foo()
    j += 1
    ret += foo()
    j += 1
    ret += foo()
    i += 1
    ret += foo()
    ret += bar()
    ret += baz(*[1000+i for i in range(13)])
    return (0, ret, "")

data = [
    [],
]
