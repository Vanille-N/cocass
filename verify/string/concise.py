def strcmp(lt, rt):
    for cl,cr in zip(lt + '\000'*len(rt), rt + '\000'*len(lt)):
        if cl != cr:
            return ord(cl) - ord(cr)
    return 0


def expect(*args):
    if len(args) == 2:
        return (0, "{}\n".format(len(args[1])), "")
    elif len(args) == 3:
        return (0, "{}\n".format(strcmp(*args[1:])), "")
    elif len(args) == 4:
        return (0, "".join(args[1:]) + '\n', "")
    else:
        return (1, "", "")

data = [
    [],
    [""],
    ["aoeuhtns"],
    ["fffff"],
    ["abc", "def"],
    ["abc", "abcd"],
    ["abc", "ab"],
    ["fffffff", "fffffff"],
    ["foo", "bar", "baz"],
    ["Hell", "o, Wor", "ld!"],
]
