def verify(*args):
    res = ""
    i = -1
    while True:
        i += 1
        if i == 1:
            continue
        elif i == 3 or i == 5:
            res += '\n'
        elif i == 10:
            return (0, res, "")
        else:
            res +=  "{} ".format(i)

data = [
    [],
]
