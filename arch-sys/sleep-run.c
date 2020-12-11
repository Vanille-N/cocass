int main()
{
	if (fork())
	{
		wait(NULL);	// père : attendre fin du fils
	}
	else
	{
		int i,j;	// fils : attente active
		for (i = 0; i < 10000; i++)
			for (j = 0; j < 100000; j++);
		printf ("%d %d\n",i,j);
	}
}
