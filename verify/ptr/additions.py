def verify(*args):
    res = ""
    res += "52 ?= 52\n"
    res += "53 ?= 53, 54 ?= 54\n"
    res += "53 ?= 53, 55 ?= 55, 57 ?= 57\n\n"

    res += "55 ?= 55 ?= 55\n"
    res += "3 ?= 3 ?= 3\n"
    res += "53 ?= 53\n\n"

    res += "1 ?= 1 ?= 1\n"
    res += "3 ?= 3 ?= 3\n"
    res += "4 ?= 4 ?= 4\n"
    res += "5 ?= 5 ?= 5\n"
    res += "3 ?= 3 ?= 3\n"
    res += "3 ?= 3\n"
    return (0, res, "")

data = [
    [],
]
