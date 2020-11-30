int and(int x, int y) {
    printf("%d & %d = %d\n", x, y, x & y);
}

int or(int x, int y) {
    printf("%d | %d = %d\n", x, y, x | y);
}

int xor(int x, int y) {
    printf("%d ^ %d = %d\n", x, y, x ^ y);
}

int main() {
    int i, j;
    for (i = 0; i < 20; i++) {
        for (j = i; j < 20; j++) {
            and(i, j);
            or(i, j);
            xor(i, j);
        }
    }
}
