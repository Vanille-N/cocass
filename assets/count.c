int main() {
    int i, j;
    int* fmtloop;
    int* fmtend;
    i = 0;
    fmtloop = "i = %d\n";
    fmtend = "i ended at %d\n\n";
    while ((j = i++) != 10) {
        printf(fmtloop, i);
        printf("j = %d\n", j);
    }
    printf("j ended at %d\n", i);
    printf(fmtend, j);
    for (i = 0; i < 10; i++) {
        printf("i = %d\n", i);
    }
    printf("i at %d\n\n", i);
    for (i = 15; i != -1; i--) {
        printf(fmtloop, i);
    }
    printf(fmtend, i);
    i = -25;
    while ((i++) != -3) {
        printf(fmtloop, i);
    }
    printf(fmtend, i);
}
