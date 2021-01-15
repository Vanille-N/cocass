void rsort (int N, int lg, int* tab) {
    int m = tab[0];
    for (int n = 0; n < N; n++) (m < tab[n]) ? m = tab[n] : 0;
    int M = 1 << lg;
    int* access = malloc(M*QSIZE);
    int* cpy = malloc(N*QSIZE);
    for (int i = 0; i < N; i++) cpy[i] = malloc(2*QSIZE);
    int b = 0;
    for (int n = 0; n < N; n++) cpy[n][0] = tab[n];
    for (int filter = M-1, d = 0; filter <= 4*m; filter <<= lg, b = 1-b, d += lg) {
        for (int m = 0; m < M; m++) access[m] = 0;
        for (int n = 0; n < N; n++) access[((cpy[n][b])&filter)>>d]++;
        for (int m = 1; m < M; m++) access[m] += access[m-1];
        for (int n = N-1; n >=0; n--) cpy[--access[((cpy[n][b])&filter)>>d]][1-b] = cpy[n][b];
    }
    for (int n = 0; n < N; n++) tab[n] = cpy[n][b];
    free(access);
    for (int i = 0; i < N; i++) free(cpy[i]);
    free(cpy);
}

int main () {
    int N ;
    printf("Enter array size: "); scanf("%ld", &N) ;
    int* tab = malloc(N*QSIZE) ;
    printf("Enter %d elements:\n", N);
    for (int n = 0; n < N; n++) scanf("%ld", &tab[n]);
    for (int n = 0; n < N; n++) printf("%d ", tab[n]);
    printf("\nNow sorting\n");
    rsort(N, 2, tab) ;
    printf("Done!\n");
    for (int n = 0; n < N; n++) printf("%d ", tab[n]);
    putchar('\n') ;
}
