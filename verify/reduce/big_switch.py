def foo(i):
    if -9 <= int(i) <= 99:
        return i
    else:
        return "Other"

def verify(*args):
    return (0, "\n".join([foo(x) for x in args[1:]]) + "\n", "No more arguments\n")

data = [
    [*"0 1 2 3 4 5 6".split(" ")],
    [*"-11 -10 -9 -8 -7 -6 97 98 99 100 101".split(" ")],
    [*"15 12 5 78 96 32 4 0 -9 85 96".split(" ")],
    [str(i) for i in range(-15, 105)],
]
