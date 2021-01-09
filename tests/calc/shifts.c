int main() {
    int i, j;

    for (i = 0; i < 1000; i++) {
        for (j = 0; j < 5; j++) {
            printf("%ld ", i << j);
            printf("%ld ", i >> j);
        }
        putchar('\n');
    }
}
