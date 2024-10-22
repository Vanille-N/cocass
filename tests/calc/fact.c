#ifndef MCC
#include <stdio.h>
#include <stdlib.h>
#endif

int fact (int n) {
    int res = 1;
    while (n != 0) {
        res *= n;
        n--;
    }
    return res;
}

int main (int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: ./fact <n>\ncalcule et affiche la factorielle de <n>.\n");
        fflush(stderr);
        exit(10); /* non mais! */
    }
    int n = atoi(argv[1]);
    if (n < 0) {
        fprintf(stderr, "Ah non, quand meme, un nombre positif ou nul, s'il-vous-plait...\n");
        fflush(stderr);
        exit(10);
    }
    int res = fact(n);
    printf("La factorielle de %d vaut %d (en tout cas, modulo 2^32...).\n", n, res);
    return 0;
}
