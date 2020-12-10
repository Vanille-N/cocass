import os

def expect(*args):
    return (0, "$PATH = {}\n".format(os.getenv("PATH")), "")

data = [
    [],
]
