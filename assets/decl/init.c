int i = 1;
int j = 2, k = 3;

int foo() {
    int l = 1;
    int m = 2, n = 3;
    int o = n, p = o;
    printf("%d %d %d %d %d %d %d %d", i, j, k, l, m, n, o, p);
}

int main() {
    foo();
}
