exec(open("verify/overflow.py").read())

def verify(*args):
    return (0, "Hello, World!\nMy name is {}.\nI have {} arguments.\n".format(args[0], len(args)-1), "")

data = [
    [],
    ["foo"],
    ["eggs", "and", "spam"],
]
