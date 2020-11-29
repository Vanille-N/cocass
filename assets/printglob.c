int i;
int j;
int *k;

int foo() {
    printf("foo: %d + %d -> %d\n", i, j, k[i+j]);
}

int bar() {
    printf("0:%d\n1:%d\n2:%d\n3:%d\n4:%d\n5:%d\n6:%d\n7:%d\n8:%d\n9:%d\nA:%d\nB:%d\nC:%d\n", 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
}

int baz(int x0, int x1, int x2, int x3, int x4, int x5, int x6, int x7, int x8, int x9, int xA, int xB, int xC) {
    printf("0:%d\n1:%d\n2:%d\n3:%d\n4:%d\n5:%d\n6:%d\n7:%d\n8:%d\n9:%d\nA:%d\nB:%d\nC:%d\n", x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, xA, xB, xC);
}

int main() {
    i = 0;
    j = 0;
    k = malloc(6*SIZE);
    k[0] = 1000; k[1] = 100; k[2] = 200;
    k[3] = 300; k[4] = 400;
    foo(); i++;
    foo(); j++;
    foo(); j++;
    foo(); i++;
    foo();
    bar();
    baz(1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012);
    fflush(stdout);
}
