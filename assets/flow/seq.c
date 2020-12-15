int main() {
    int i = 0, j = 1;
    i++, j++;
    printf("%d %d\n", i, j);
    for (i = 0, j = 0; i < 10; i++, j--) {
        printf("%d %d\n", i, j);
    }
}
