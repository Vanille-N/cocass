def verify(*args):
    s = "Formatting string: <%s> <%s> <%s>"
    fmt = s.replace("%s", "{}")
    res = fmt.format(s, "foo", "bar") + '\n'
    return (0, res, "")

data = [
    [],
]
