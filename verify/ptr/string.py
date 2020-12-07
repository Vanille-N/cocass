def verify(*args):
    s = args[0]
    res = ""
    for i,c in enumerate(s):
        res += "str[{: >2}] = <{}> ({: >3})\n".format(i, c, ord(c))
    res += '\n'
    for i in range(len(s)):
        res += "str[{: >2}] = <{}> ({: >3})\n".format(i, chr(ord('a') + i), ord('a') + i)
    return (0, res, "")

data = [
    [],
]
