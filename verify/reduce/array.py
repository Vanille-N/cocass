def expect(*args):
    res = ""
    res += "0x04030201\n"
    res += "0x05040302\n"
    res += "0x07060504\n"
    res += "0x0B0A0908\n"
    res += "0x05040302\n" * 2
    res += "0x07060504\n" * 2
    res += "0x0B0A0908\n" * 2
    res += "0x13121110\n" * 2
    res += "0x07030502\n"
    res += "0x05070305\n"
    res += "0x07060507\n"
    res += "0x0B0A090B\n"
    res += "0x05070305\n"
    res += "0x07060507\n"
    res += "0x0B0A090B\n"
    res += "0x13121112\n"
    return (0, res, "")

data = [
    [],
]
