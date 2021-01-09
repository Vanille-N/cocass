int i = 1;
int j = 2, k = 3 * QSIZE;

int foo() {
    int l = 1;
    int m = 2, n = 3;
    int o = n;
    printf("%d %d %d %d %d %d %d\n", i, j, k, l, m, n, o);
}

int main() {
    foo();
}
