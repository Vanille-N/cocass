def foo(x):
    return "I am foo and I have received {}\n".format(x)

def apply(fn, arg):
    return fn(arg)

def verify(*args):
    return (0, apply(foo, 10), "")

data = [
    [],
]
