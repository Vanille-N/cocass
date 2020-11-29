exec(open("verify/overflow.py").read())

def verify(*args):
    return (0, "Hello, World!\nMy name is ./assets/hello.\nI have {} arguments".format(len(args)), "")

data = [
    [],
    ["foo"],
    ["eggs", "and", "spam"],
]
