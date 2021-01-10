int main() {
    for (int i = 0; i < 10; i++) {
        if (i == 5) break;
        printf("%d ", i);
    }
    putchar('\n');
    for (int i = 0; i < 10; i++) {
        if (i == 7) break;
        for (int j = 0; j < 10; j++) {
            if (i == j) break;
            printf("(%d,%d) ", i, j);
        }
        putchar('\n');
    }
    int i = 0;
    while (1) {
        if (i == 10) {
            printf("exit.\n");
            break;
        }
        printf("%d ", i++);
    }
}
