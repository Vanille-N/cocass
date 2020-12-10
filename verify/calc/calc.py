def calculate(op, lhs, rhs):
    if op == '-':
        return ("{} - {} = {}\n".format(lhs, rhs, lhs - rhs), "")
    elif op == '+':
        return ("{} + {} = {}\n".format(lhs, rhs, lhs + rhs), "")
    elif op == 'x':
        return ("{} x {} = {}\n".format(lhs, rhs, lhs * rhs), "")
    elif op == '/':
        if rhs == 0:
            return ("", "Cannot divide by zero: {} / {}\n.".format(lhs, rhs))
        return ("{} / {} = {}\n".format(lhs, rhs, lhs // rhs), "")
    elif op == '%':
        if rhs == 0:
            return ("", "Cannot divide by zero: {} % {}\n.".format(lhs, rhs))
        return ("{} % {} = {}\n".format(lhs, rhs, lhs % rhs), "")
    else:
        return ("", "Unknown operator {}.\n".format(op))

def expect(*args):
    out = ""
    err = ""
    if len(args) == 1 or len(args) % 3 != 1:
        return (1, "", "Usage: calc <op> <m> <n> [<op> <m> <n> ...]\n  where <m>, <n>: integers; <op>: +, x, /, %, -")
    for i in range(len(args) // 3):
        try:
            m = int(args[3*i+2])
        except:
            err += "{} is not a valid base 10 integer.\n".format(args[3*i+2])
            continue
        try:
            n = int(args[3*i+3])
        except:
            err += "{} is not a valid base 10 integer.\n".format(args[3*i+3])
            continue
        (o, e) = calculate(args[3*i+1], m, n)
        out += o
        err += e
    return (0, out, err)

data = [
    [],
    ["~"],
    [*"- 52".split(' ')],
    [*"- 45 86".split(' ')],
    [*"+ 10 12 + 5 15 + 2 -154 + -145 -85".split(' ')],
    [*"x 45 86 x 78 -4 x -10 -10".split(' ')],
    [*"/ 76 3".split(' ')],
    [*"% 7654 7".split(' ')],
]
