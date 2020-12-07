int and(int x, int y) {
    printf("%d & %d = %d\n", x, y, x & y);
}

int or(int x, int y) {
    printf("%d | %d = %d\n", x, y, x | y);
}

int xor(int x, int y) {
    printf("%d ^ %d = %d\n", x, y, x ^ y);
}

int not(int x) {
    printf("~%d = %d\n", x, ~x);
}

int main() {
    int i, j;
    for (i = 0; i < 200; i++) {
        for (j = i; j < 200; j++) {
            and(i, j);
            or(i, j);
            xor(i, j);
        }
        not(i);
    }
}