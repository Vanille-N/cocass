def expect(*args):
    i = int(args[1])
    return [
        (0, "", ""),
        (111, "", "Unhandled exception Foo(15)\n"),
        (111, "", "Unhandled exception Foo(0)\n"),
        (111, "", "Unhandled exception Bar(1)\n"),
        (0, "Normal exit\n", ""),
        (0, "Failed n.1 with Foo(0)\nNormal exit\n", ""),
        (111, "", "Unhandled exception Bar(1)\n"),
        (0, "Normal exit\n", ""),
        (111, "Ended n.2\n", "Unhandled exception Foo(0)\n"),
        (0, "Failed n.2 with Bar(1)\nEnded n.2\nNormal exit\n", ""),
        (0, "Ended n.2\nNormal exit\n", ""),
        (111, "Ended n.2\n", "Unhandled exception Foo(0)\n"),
        (111, "Ended n.2\n", "Unhandled exception Bar(1)\n"),
        (0, "Ended n.2\nNormal exit\n", ""),
        (0, "Caught Foo(0)\nFinally...\nNormal exit\n", ""),
        (0, "Caught Hello, World!\nCaught Hello, World! again\nNormal exit\n", ""),
        (111, "Caught Bar(1)\n", "Unhandled exception Bar(1)\n"),
        (0, "Finally...\nNormal exit\n", ""),
        (0, "Everything is fine.\nNo error occurred.\nNormal exit\n", "")
    ][i]


data = [[str(i)] for i in range(1, 19)]
