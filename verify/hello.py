exec(open("verify/overflow.py").read())

def verify(*args):
    return (0, "Hello, World!\nMy name is ./assets/hello.\nI have {} arguments.\n".format(len(args)-1), "")

data = [
    [],
    ["foo"],
    ["eggs", "and", "spam"],
]
