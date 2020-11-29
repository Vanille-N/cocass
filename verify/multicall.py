def bar1(x, y):
    return x + y

def bar2(x, y):
    return y - x

def foo(x):
    z = x
    z = bar1(x, z)
    z = bar2(x, z)
    return z

def main(argc):
    x = foo(argc)
    y = 3
    y = foo(y)
    x = x + y
    return x

def verify(*args):
    return (main(len(args)+1), "", "")

data = [
    [],
    ["1"],
    ["hello", "world"],
    ["eggs", "and", "spam"],
    ["foo", "bar", "baz", "quux"],
]
