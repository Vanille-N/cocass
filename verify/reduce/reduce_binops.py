def verify(*args):
    ret = ""

    ret += "ADD "
    ret += "{} ".format(1656 + 4582)
    ret += "{} ".format(18 + -78)
    ret += "{} ".format(-482 + -7569)
    ret += "{} ".format(15 + 45 + 689 + 96 + 47 + 45)
    ret += '\n'

    ret += "SUB "
    ret += "{} ".format(4693 - 7582)
    ret += "{} ".format(482 - -15)
    ret += "{} ".format(-1445 - 4782)
    ret += "{} ".format(45 - 5 - -12 - 5)
    ret += '\n'

    ret += "MUL "
    ret += "{} ".format(425 * 736)
    ret += "{} ".format(72 * -15)
    ret += "{} ".format(-452 * -69)
    ret += "{} ".format(-45 * 5 * 2 * 4 * -7)
    ret += '\n'

    ret += "DIV "
    ret += "{} ".format(15266 // 45)
    ret += "{} ".format(-144443 // 889 + 1) # difference here
    ret += "{} ".format(-496854 // -321)
    ret += "{} ".format(42659 // -152 + 1) # difference here
    ret += '\n'

    ret += "MOD "
    ret += "{} ".format(1236546 % 156)
    ret += "{} ".format(695816 % 54)
    ret += "{} ".format(-(654 % 52)) # difference here
    ret += "{} ".format(4546986 % 45) # difference here
    ret += "{} ".format(-558 % -54)
    ret += '\n'

    ret += "AND "
    ret += "{} ".format(1236546 & 156)
    ret += "{} ".format(695816 & 54)
    ret += "{} ".format(-654 & 52)
    ret += "{} ".format(4546986 & -45)
    ret += "{} ".format(-558 & -54)
    ret += '\n'

    ret += "XOR "
    ret += "{} ".format(1236546 ^ 156)
    ret += "{} ".format(695816 ^ 54)
    ret += "{} ".format(-654 ^ 52)
    ret += "{} ".format(4546986 ^ -45)
    ret += "{} ".format(-558 ^ -54)
    ret += '\n'

    ret += "OR "
    ret += "{} ".format(1236546 | 156)
    ret += "{} ".format(695816 | 54)
    ret += "{} ".format(-654 | 52)
    ret += "{} ".format(4546986 | -45)
    ret += "{} ".format(-558 | -54)
    ret += '\n'

    ret += "NEG "
    ret += "{} ".format(-0)
    ret += "{} ".format(-15)
    ret += "{} ".format(-(-152))
    ret += '\n'

    ret += "NOT "
    ret += "{} ".format(~0)
    ret += "{} ".format(~1584)
    ret += "{} ".format(~(-1474))
    ret += '\n'

    ret += "SHR "
    ret += "{} ".format(15246 >> 2)
    ret += "{} ".format(-426 >> 3)
    ret += '\n'

    ret += "SHL "
    ret += "{} ".format(15246 << 2)
    ret += "{} ".format(-426 << 3)
    ret += '\n'

    return (0, ret, "")

data = [
    [],
]
