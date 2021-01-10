int main (int argc, char **argv) {
    if (argc != 2) {
        fprintf (stderr, "Usage: ./sieve <n>\ncalcule et affiche les nombres premiers inferieurs a <n>.\n");
        fflush (stderr);
        exit (10); /* non mais! */
    }
    int n = atoi (argv[1]); // conversion chaine -> entier.
    if (n < 2) {
        fprintf (stderr, "Ah non, quand meme, un nombre >=2, s'il-vous-plait...\n");
        fflush (stderr);
        exit (10);
    }
    int* bits = malloc (QSIZE*n); // allouer de la place pour n entiers (booleens).
    // Ca prend 64 foit trop de place, mais ce serait compliqué de traiter des bits individuels
    if (bits==NULL) {
        fprintf (stderr, "%d est trop gros, je n'ai pas assez de place memoire...\n");
        fflush (stderr);
        exit (10);
    }
    zero_sieve (bits, n);
    bits[0] = bits[1] = 1;
    fill_sieve (bits, n);
    print_sieve (bits, n);
    free (bits); // et on libere la place memoire allouee pour bits[].
    return 0;
}

int zero_sieve (int *bits, int n) {
    for (int i = 0; i < n; i++) bits[i] = 0;
    return 0;
}

int fill_sieve (int *bits, int n) {
    for (int last_prime = 2; last_prime < n;){
        cross_out_prime (bits, n, last_prime);
        while (++last_prime < n && bits[last_prime]);
    }
    return 0;
}

int cross_out_prime (int *bits, int n, int prime) {
    for (int delta = prime; (prime = prime + delta) < n;) bits[prime] = 1;
    return 0;
}

int print_sieve (int *bits, int n) {
    printf("Les nombres premiers inferieurs a %d sont:\n", n);
    char* delim = "  ";
    int k = 0;
    for (int i = 0; i < n; i++) {
        if (bits[i]==0) {
            printf ("%s%8d", delim, i);
            if (++k >= 4) {
                printf("\n"); // retour à la ligne.
                k = 0;
                delim = "  ";
            } else {
                printf (" "); // espace.
            }
        }
    }
    fflush (stdout); // on vide le tampon de stdout, utilise par printf().
    return 0;
}
