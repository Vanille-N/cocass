int main ()
{
	printf("Je suis le processus numero %d\n",getpid());

	// get an initial value of x for both parent and child
	int x = 0;
	printf("x = "); fflush(stdout);
	scanf("%ld",&x);

	int y = fork();

	if (y) {
		// parent: return value of fork() is non-zero, contains child id
		while (1) { sleep(2); printf("[pere] x=%d\n",x++); }
	} else {
		// child: return value of fork() is zero
		while (1) { sleep(5); printf("[fils] x=%d\n",x++); }
	}
}
