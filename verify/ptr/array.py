def expect(*args):
    res = ""
    res += "arr[2] = 101 ?= 101; "
    res += "arr[2] = 101 ?= 101; "
    res += "arr[1] = 200 ?= 200; "
    res += "arr[0] = 101 ?= 101; "
    res += "arr[1] = 201 ?= 201 ?= 201; "
    return (0, res, "")

data = [
    [],
]
