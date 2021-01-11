def expect(*args):
    res = ""
    res += 'char* a = "101"\n'
    res += 'bin_to_int(a, 3) = 5\n'
    res += 'bin_to_int(a, 2) = 1\n'
    res += 'bin_to_int("110f2o", 6) = 0\n'
    res += 'bin_to_int("110f2o", 3) = 3\n'
    return (0, res, "")

data = [
    [],
]
