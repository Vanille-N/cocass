#define DISPLAY(X) printf(#X" = %d\n", (X));

void minimax (int* tab, int len, int* min, int* max) {
    *min = *max = *tab;
    for (int i = 1; i < len; i++) {
        if (tab[i] < *min) { *min = tab[i]; }
        if (tab[i] > *max) { *max = tab[i]; }
    }
}


int main (int argc, char** argv) {
    int* tab = malloc((argc-1)*QSIZE);
    for (int i = 1; i < argc; i++) {
        tab[i-1] = atol(argv[i]);
    }
    int min, max;
    minimax(tab, argc-1, &min, &max);
    DISPLAY(min);
    DISPLAY(max);
}
