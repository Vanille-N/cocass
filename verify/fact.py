exec(open("verify/overflow.py").read())

def factorial(n):
    f = 1
    for i in range(1, n+1):
        f *= i
    return f

def verify(*args):
    if len(args) != 1:
        return (10, "", "Usage: ./fact <n>\ncalcule et affiche la factorielle de <n>.\n")
    else:
        try:
            n = int(args[0])
        except:
            n = 0
        if n < 0:
            return (10, "", "Ah non, quand meme, un nombre positif ou nul, s'il-vous-plait...\n")
        f = sdword(factorial(n))
        return (0, "La factorielle de {} vaut {} (en tout cas, modulo 2^32...).\n".format(n, f), "")

data = [
    [],
    ["0"],
    ["1"],
    ["4"],
    ["20"],
    ["foo"],
    ["-1"],
    ["2", "1"],
]
