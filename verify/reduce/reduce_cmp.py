def verify(*args):
    res = ""
    res += "Yes:\n"
    res += "\t5 < 6: {}\n".format(int(5 < 6))
    res += "\t5 <= 6: {}\n".format(int(5 <= 6))
    res += "\t5 == 5: {}\n".format(int(5 == 5))
    res += "\t!(6 <= 5): {}\n".format(int(not (6 <= 5)))
    res += "\t!(6 < 5): {}\n".format(int(not (6 < 5)))
    res += "\t6 > 5: {}\n".format(int(6 > 5))
    res += "\t6 >= 5: {}\n".format(int(6 >= 5))
    res += "\t6 != 5: {}\n".format(int(6 != 5))
    res += "No:\n"
    res += "\t6 < 5: {}\n".format(int(6 < 5))
    res += "\t6 <= 5: {}\n".format(int(6 <= 5))
    res += "\t5 == 6: {}\n".format(int(5 == 6))
    res += "\t!(5 < 6): {}\n".format(int(not (5 < 6)))
    res += "\t!(5 <= 6): {}\n".format(int(not (5 <= 6)))
    res += "\t5 > 6: {}\n".format(int(5 > 6))
    res += "\t5 >= 6: {}\n".format(int(5 >= 6))
    res += "\t5 != 5: {}\n".format(int(5 != 5))
    return (0, res, "")

data = [
    [],
]
