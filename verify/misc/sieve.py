def expect(*args):
    if len(args) != 2:
        return (10, "", "Usage: ./sieve <n>\ncalcule et affiche les nombres premiers inferieurs a <n>.\n")
    n = int(args[1])
    if n < 2:
        return (10, "", "Ah non, quand meme, un nombre >=2, s'il-vous-plait...\n")
    ok = [True] * n
    ok[0] = ok[1] = False
    for i in range(2, n):
        if ok[i]:
            for j in range(i*2, n, i):
                ok[j] = False
    res = "Les nombres premiers inferieurs a {} sont:\n".format(n)
    delim = "  ";
    primes = [p for p in range(n) if ok[p]]
    for i in range(0, len(primes), 4):
        for j in range(4):
            if i+j >= len(primes):
                break
            res += "  {: 8}".format(primes[i+j])
            if j != 3:
                res += ' '
            else:
                res += '\n'
    return (0, res, "")

data = [
    [],
    ["0"],
    ["2"],
    ["10"],
    ["50"],
    ["100"],
    ["500"],
    ["1000"],
]
