int* p, q;

// Utilisation de deux pipe pour créer un canal de communication
// dans les deux sens. Ici, on s'en sert pour convertir quelques
// caractères Unicode. (uconv doit être installé dans ce cas,
// mais le principe marche avec n'importe quel programme.)

void pere ()
{
	char *s = "Ĳ ﬀ ½\n";
	char *t = malloc(100);

	close(*p); close(*(q+DSIZE));
	write(*(p+DSIZE),s,strlen(s));
	close(*(p+DSIZE));
	*(t + read(*q,t,100)) = 0;
	close(*q);
	printf("la sortie est %s\n",t);
}

void fils ()
{
	dup2(*p,0);
	dup2(*(q+DSIZE),1);
	close(*p); close(*q);
	close(*(p+DSIZE)); close(*(q+DSIZE));
	execlp("uconv","uconv","-x","NFKD",NULL);
}

int main()
{
    p = malloc(2*DSIZE);
    q = malloc(2*DSIZE);
	pipe(p);
	pipe(q);
	if (fork()) pere(); else fils();
    free(p);
    free(q);
}
