def overflow_correct(value, bits, signed):
    base = 1 << bits
    value %= base
    return value - base if signed and value.bit_length() == bits else value

byte, sbyte, word, sword, dword, sdword, qword, sqword = (
    lambda v: overflow_correct(v, 8, False), lambda v: overflow_correct(v, 8, True),
    lambda v: overflow_correct(v, 16, False), lambda v: overflow_correct(v, 16, True),
    lambda v: overflow_correct(v, 32, False), lambda v: overflow_correct(v, 32, True),
    lambda v: overflow_correct(v, 64, False), lambda v: overflow_correct(v, 64, True)
)
