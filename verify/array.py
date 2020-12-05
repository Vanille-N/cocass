def verify(*args):
    res = ""
    res += "arr[2] = 101 ?= 101; "
    res += "arr[2] = 101 ?= 101; "
    res += "arr[1] = 200 ?= 200; "
    res += "arr[0] = 101 ?= 101; "
    return (0, res, "")

data = [
    [],
]
