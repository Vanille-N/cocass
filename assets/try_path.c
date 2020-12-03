int path(int i) {
    try {
        printf("A 0123456789\n");
        try {
            printf("B 0123456789\n");
            try {
                printf("C 0123456789\n");
                try {
                    printf("D 0123456789\n");
                    if (i%2 == 0) {
                        printf("E 0.2.4.6.8.\n");
                        throw Even(i);
                    } else if (i == 7) {
                        printf("F .......7..\n");
                        throw Lucky("Found the number 7");
                    } else {
                        printf("G 0123456789\n");
                        if (i == 1) throw One(0);
                        printf("H 0.23456789\n");
                    }
                printf("I ...3.5...9\n");
                } catch (Lucky s) {
                    printf("J .......7..\n");
                    printf("Exception(%s)\n", s);
                    throw Lucky(s);
                } catch (Even x) {
                    printf("K 0.2.4.6.8.\n");
                    if (x < 5) throw Small(x);
                    printf("L ......6.8.\n");
                } catch (One _) {
                    printf("M .1.......\n");
                    throw Odd(1);
                } finally {
                    printf("O ...3.56.89\n");
                }
                printf("P ...3.56.89\n");
            } finally {
                printf("Q 0123456789\n");
            }
            printf("R ...3.56.89\n");
            if (i % 2 == 1) throw Odd(i);
        } catch (Odd x) {
            printf("S .1.3.5...9\n");
        } catch (Small x) {
            printf("T 0.2.4....\n");
        } finally {
            printf("U 0123456789\n");
        }
        if (i % 2 == 0) throw Even(i);
        printf("V .1.3.5...9\n");
        throw Odd(i);
    } catch (Even x) {
        printf("W 0.2.4.6.8.\n");
        throw Even(x);
    } catch (Lucky s) {
        printf("Exception(%s) rethrown\n", s);
        printf("X .......7..");
        throw Odd(7);
    } catch (One _) {
        printf("Y .1........\n");
        throw Odd(1);
    } finally {
        printf("Z 0123456789\n");
        if (i == 1) throw Odd(1);
    }
}

int main(int argc, char** argv) {
    int n;
    if (argc != 2) {
        fprintf(stderr, "Takes exactly one argument: <n>\n");
        throw WrongArgs(argc);
    }
    try {
        n = atol(argv[1]);
        if (n < 0 || n > 9) throw Invalid(n);
        path(n);
    } catch (Even x) {
        printf("Received even number %d\n", x);
    } catch (Odd x) {
        printf("Received odd number %d\n", x);
    } catch (Invalid x) {
        printf("Not a good number: %d\n", x);
    }
}
