def bien_parentesee(s):
    diff = 0
    for c in s:
        if c == '(': diff += 1
        elif c == ')':
            if diff == 0: return False
            else: diff -= 1
    return diff == 0

def expect(*args):
    res = ""
    for s in args[1:]:
        res += "{} -> {}\n".format(s, int(bien_parentesee(s)))
    return (0, res, "")

data = [
    ["(())"],
    ["(foo(bar)(baz)q()uux)"],
    [")("],
    ["((((()"],
    ["()))))"],
    ["[(]{)}{()"],
]
