int main()
{
	void *sb = sbrk(0);
	printf("beginning, sbrk=%p\n",sb);

    int i;
	for (i = 1; i <= 50; i++)
	{
		char *m = malloc(15000);
		void *nsb = sbrk(0);
		printf("round #%2d, sbrk=%p",i,nsb);
		if (sb != nsb) printf(" (change of %ld)",nsb-sb);
		printf("\n");
		sb = nsb;
	}
}
