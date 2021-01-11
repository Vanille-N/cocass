from subprocess import Popen, PIPE

info_str = "\nusage: mwc [-l|-w|-c] FILE\n  count (l)ines, (w)ords, (c)haracters in FILE (default -w)\n"


def expect(*args):
    if len(args) == 1: return (2, "Not enough arguments" + info_str, "")
    file = None
    mode = None
    for a in args[1:]:
        if a[0] == '-':
            if mode is not None: return (1, "Too many optional arguments" + info_str, "")
            if a[1] in ['w', 'c', 'l']:
                mode = a[1]
            else: return (1, "Invalid optional argument" + info_str, "")
            if len(a) > 2: return (2, "Optional argument too long" + info_str, "")
        elif file is not None: return (2, "Too many positional arguments" + info_str, "")
        else: file = a
    if file is None: return (2, "Not enough positional arguments" + info_str, "")
    if mode is None: mode = 'w'
    try:
        with open(file, 'r') as f:
            pass
    except FileNotFoundError:
        return (3, "File does not exist" + info_str, "")
    cproc = Popen(["wc", '-' + mode, file], stdin=PIPE, stdout=PIPE, stderr=PIPE)
    cout, _ = cproc.communicate()
    return (0, cout.decode('utf-8'), "")

data = [
    ["-l", "Makefile"],
    ["Makefile", "-l"],
    ["-w", "compile.ml"],
    ["-c", "cparse.mly"],
    ["-foo", "Makefile"],
    ["-f", "Makefile"],
    [],
    ["-c", "-c", "cparse.ml"],
    ["-l", "inexistant.file"],
    ["Makefile"],
    ["Makefile", "Makefile"],
    ["-c"],
]
