int foo(int x1, int x2, int x3, int x4, ...) {
    int* ap;
    int arg;
    printf("1:%d 2:%d 3:%d 4:%d\n", x1, x2, x3, x4);
    va_start(ap);
    while ((arg = va_arg(ap)) != NULL) {
        printf("Next: %d\n", arg);
    }
    printf("Done.\n\n");
}

int bar(int x1, int x2, int x3, int x4, int x5, int x6, int x7, int x8, ...) {
    int* ap;
    int arg;
    printf("1:%d 2:%d 3:%d 4:%d\n", x1, x2, x3, x4);
    printf("5:%d 6:%d 7:%d 8:%d\n", x5, x6, x7, x8);
    va_start(ap);
    while ((arg = va_arg(ap)) != NULL) {
        printf("Next: %d\n", arg);
    }
    printf("Done.\n\n");
}

void write(int nb, ...) {
    int* ap;
    int i;
    va_start(ap);
    for (i = 0; i < nb; i++) {
        printf("argument #%d: %d\n", i, va_arg(ap));
    }
    putchar('\n');
}

void twice(int nb, ...) {
    int* ap1, ap2;
    int i;
    va_start(ap1);
    va_start(ap2);
    for (i = 0; i < nb; i++) {
        printf("two at once: %d %d\n", va_arg(ap1), va_arg(ap2));
    }
    putchar('\n');
}

int main() {
    // foo(1,2,3); // KO
    foo(1,2,3,4, NULL);
    foo(1,2,3,4,5,6, NULL);
    foo(1,2,3,4,5,6,7,8,9,10,11,12, NULL);
    // bar(1,2,3); // KO
    bar(1,2,3,4,5,6,7,8,9,10,11,12,13, NULL);
    write(2, 101,102);
    write(5, 101,102,103,104,105);
    write(15, 101,102,103,104,105,106,107,108,109,110,111,112,113,114,115);
    twice(5, 1,2,3,4,5);
}
