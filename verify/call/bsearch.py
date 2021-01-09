def search(arr, item):
    # (NOT a bsearch)
    return arr.index(item)

def is_inc(arr):
    for i in range(1, len(arr)):
        if arr[i-1] >= arr[i]:
            return False
    return True

def expect(*args):
    i = 1
    n = len(args)
    items = []
    while i < n:
        if args[i] == "--key":
            key = int(args[i+1])
            i += 1
        else:
            items.append(int(args[i]))
        i += 1
    if not is_inc(items):
        return (1, "", "List is not increasing")
    try:
        p = search(items, key)
        return (0, "Found item = {} at position {}\n".format(key, p), "")
    except ValueError:
        return (0, "Item = {} could not be found\n".format(key), "")

data = [
    "1 2 3 5 8 9 --key 10".split(),
    "1 2 5 --key 2 6 7".split(),
    "5 4 3".split(),
    "--key 10 1".split(),
    "2 2 4 6 8".split(),
    "--key 5 1 3 5 6 --key 7 8 9 --key 3".split(),
]
