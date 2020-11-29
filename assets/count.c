int main() {
    int i, j;
    i = 0;
    while ((j = i++) != 10) {
        printf("i=%d, j=%d\n", i, j);
    }
    printf("(i, j) ended at (%d, %d)\n\n", i, j);
    for (i = 0; i < 10; i++) {
        printf("i is %d\n", i);
    }
    printf("i at %d\n\n", i);
    for (i = 15; i != -1; i--) {
        printf("i is %d\n", i);
    }
    printf("i ended at %d\n\n", i);
    i = -25;
    while ((i++) != -3) {
        printf("i = %d\n", i);
    }
    printf("i ended at %d\n\n", i);
}
