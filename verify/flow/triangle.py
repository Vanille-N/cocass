chr = '*'

def line(amount):
    return chr * amount + '\n'

def expect(*args):
    max = int(args[1])
    return (0, "".join(line(amount) for amount in range(1, max)), "")

data = [
    ["1"],
    ["4"],
    ["5"],
    ["10"],
    ["100"],
]
