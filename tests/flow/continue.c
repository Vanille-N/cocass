int main() {
    for (int i = 0; i < 10; i++) {
        if (i == 5) continue;
        printf("%d ", i);
    }
    putchar('\n');
    for (int i = 0; i < 10; i++) {
        if (i == 7 || i == 3) {
            putchar('\n');
            continue;
        }
        for (int j = 0; j < 10; j++) {
            if (i == j) {
                printf("     ");
                continue;
            }
            printf("(%d,%d) ", i, j);
        }
        putchar('\n');
    }
}
