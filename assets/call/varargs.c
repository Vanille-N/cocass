int foo(int x1, int x2, int x3, int x4, ...) {
    printf("1:%d 2:%d 3:%d 4:%d\n", x1, x2, x3, x4);
}

int bar(int x1, int x2, int x3, int x4, int x5, int x6, int x7, int x8, ...) {
    printf("1:%d 2:%d 3:%d 4:%d\n", x1, x2, x3, x4);
    printf("5:%d 6:%d 7:%d 8:%d\n", x5, x6, x7, x8);
}

void print(int nb, ...) {
    int* ap;
    int i;
    va_init(ap);
    for (i = 0; i < 10; i++) {
        printf("argument #%d: %d\n", i, va_arg(ap));
    }
}

int main() {
    // foo(1,2,3); // KO
    // foo(1,2,3,4);
    // foo(1,2,3,4,5,6);
    // foo(1,2,3,4,5,6,7,8,9,10,11,12);
    // bar(1,2,3); // KO
    // bar(1,2,3,4,5,6,7,8,9,10,11,12);
    print(2, 101,102);
    print(5, 101,102,103,104,105);
    print(15, 101,102,103,104,105,106,107,108,109,110,111,112,113,114,115);
}
