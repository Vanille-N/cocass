int main() {
    for (int i = 0; i < 1000; i++) {
        for (int j = 0; j < 5; j++) {
            printf("%ld ", i << j);
            printf("%ld ", i >> j);
        }
        putchar('\n');
    }
}
