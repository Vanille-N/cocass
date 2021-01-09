int main() {
    int i, j, k;
    i = malloc(QSIZE*3);
    *i = 52;
    printf("%d ?= 52\n", *i);
    *(i+QSIZE) = (*i)++ + 2;
    printf("%d ?= 53, %d ?= 54\n", *i,  *(i+QSIZE));
    *(i+2*QSIZE) = ++(*(i+QSIZE)) + 2;
    printf("%d ?= 53, %d ?= 55, %d ?= 57\n\n", *i, *(i+QSIZE), *(i+2*QSIZE));

    k = &i[1];
    printf("%d ?= %d ?= 55\n", i[1], *k);
    *k = 3;
    printf("%d ?= %d ?= 3\n", i[1], *k);
    k = &i;
    printf("%d ?= 53\n\n", **k);
    free(i);

    j = 1;
    i = &j;
    printf("%d ?= %d ?= 1\n", *i, j);
    j = 3;
    printf("%d ?= %d ?= 3\n", *i, j);
    j++;
    printf("%d ?= %d ?= 4\n", *i, j);
    (*i)++;
    printf("%d ?= %d ?= 5\n", *i, j);
    *i = 3;
    printf("%d ?= %d ?= 3\n", *i, j);
    k = &i;
    printf("%d ?= 3\n", **k);
}
