int p;

// On simule la commande "cat toto | wc" avec deux processus et un pipe.

void pere ()
{
	// greffer stdout sur l'entrée du pipe
	dup2(*(p+DSIZE),1);
	close(*p);
	close(*(p+DSIZE));

	// exec cat toto
	execlp("cat","cat","toto",NULL);
	printf("cat failed\n");	// never happens
}

void fils ()
{
	// faire en sort que stdin lise dans le pipe
	dup2(*p,0);
	close(*p);
	close(*(p+DSIZE));

	// exec wc
	execlp("wc","wc",NULL);
	printf("wc failed\n");	// never happens
}

int main()
{
    p = malloc(2*DSIZE);
	pipe(p);
	if (fork()) pere(); else fils();
    free(p);
}
