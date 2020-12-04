def verify(*args):
    i = 5;
    j = 6;
    res = ""
    res += "Yes:\n"
    res += "\ti < j: {}\n".format(int(i < j))
    res += "\ti <= j: {}\n".format(int(i <= j))
    res += "\ti == i: {}\n".format(int(i == i))
    res += "\t!(j <= i): {}\n".format(int(not (j <= i)))
    res += "\t!(j < i): {}\n".format(int(not (j < i)))
    res += "\tj > i: {}\n".format(int(j > i))
    res += "\tj >= i: {}\n".format(int(j >= i))
    res += "\tj != i: {}\n".format(int(j != i))
    res += "No:\n"
    res += "\tj < i: {}\n".format(int(j < i))
    res += "\tj <= i: {}\n".format(int(j <= i))
    res += "\ti == j: {}\n".format(int(i == j))
    res += "\t!(i < j): {}\n".format(int(not (i < j)))
    res += "\t!(i <= j): {}\n".format(int(not (i <= j)))
    res += "\ti > j: {}\n".format(int(i > j))
    res += "\ti >= j: {}\n".format(int(i >= j))
    res += "\ti != i: {}\n".format(int(i != i))
    return (0, res, "")

data = [
    [],
]
