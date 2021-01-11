int* p;
int q;

// On simule la commande "cat Makefile | wc" avec deux processus et un pipe.

void pere () {
    // greffer stdout sur l'entrée du pipe
    dup2(p[1], 1);
    close(p[0]);
    close(p[1]);

    // exec cat toto
    execlp("cat", "cat", "Makefile", NULL);
    printf("cat failed\n"); // never happens
}

void fils () {
    // faire en sorte que stdin lise dans le pipe
    dup2(p[0], 0);
    close(p[0]);
    close(p[1]);

    // exec wc
    execlp("wc", "wc", NULL);
    printf("wc failed\n"); // never happens
}

int main() {
    p = malloc(2*QSIZE);
    pipe(&q);
    p[0] = q & DOUBLE;
    p[1] = q >> (8*DSIZE);
    if (fork()) {
        pere();
    } else {
        fils();
    }
}
