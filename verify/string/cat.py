def cat(name):
    with open(name) as f:
        return f.read()

def expect(*args):
    return (0, ''.join(cat(f) for f in args[1:]), "")

data = [
    ["Makefile"],
    ["README.md", "main.ml", "error.ml"],
]
