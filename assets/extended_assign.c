int main() {
    int i, j;
    i = malloc(SIZE*3);
    j = 1;
    i[0] = 5; i[1] = 7; i[2] = 3;

    j += 1;
    printf("%d ?= 2\n", j);
    i[0] += 1;
    printf("%d ?= 5\n", i[0]);
    *i += 1;
    printf("%d ?= 6\n", *i);
    j *= 2;
    printf("%d ?= 4\n", j);
    i[0] *= 2;
    printf("%d ?= 12\n", i[0]);
    *i *= 2;
    printf("%d ?= 24\n", *i);
}
