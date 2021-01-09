def mean(arr):
    if arr == []: return 0
    return sum(arr) // len(arr)

def expect(*args):
    items = []
    for i in args[1:]:
        items.append(int(i))
    return (0, "{}\n".format(mean(items)), "")

data = [
    [],
    ["10"],
    "10 10 10 20".split(),
    "1 10 100 1000".split(),
    "5 7 9 3 5 1 8 2 9 3 5 1 2 7 8 4 5 6 9 9 3 2".split(),
]
