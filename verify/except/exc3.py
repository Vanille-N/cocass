def syracuse(n):
    if n == 1:
        return 0
    elif n % 2 == 0:
        return 1 + syracuse(n // 2)
    else:
        return 1 + syracuse(3*n + 1)


def expect(*args):
    always = "*Fin* (ce message doit toujours s'afficher).\n"
    if len(args) != 2:
        return (10, "", "Usage: ./exc1 <n>\ncalcule a quelle iteration une suite mysterieuse termine, en partant de <n>.\n")
    n = int(args[1])
    if n < 0:
        return (0, "", "Pas trouvé...\n" + always)
    if n == 0:
        return (0, "", "Le nombre d'entree est nul.\n" + always)
    else:
        return (0, "", "La suite termine apres {} iterations en partant de {}.\n".format(syracuse(n), n) + always)

data = [
    [],
    ["0"],
    ["1"],
    ["5"],
    ["521"],
    ["6521"],
    ["foo", "bar"],
]
