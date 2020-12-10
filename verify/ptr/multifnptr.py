def expect(*args):
    res = ""
    res += "foo1(5) = 15 ?= 15\n"
    res += "foo1(bar1(5)) = 12 ?= 12\n"
    res += "foo2(foo0(), bar1(bar0()) = 375 ?= 375\n"
    return (0, res, "")

data = [
    [],
]
