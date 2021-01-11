int main() {
    int i = 0;
    for (;;) {
        printf("%d ", i++);
        if (i == 10) break;
    }
    putchar('\n');
    for (i = 0;;) {
        printf("%d ", i++);
        if (i == 10) break;
    }
    putchar('\n');
}
