int keep_going = 1;

void catch_alarm (int sig)
{
	/* Clear the flag. */
	printf("caught alarm signal\n");
	keep_going = 0;
}

int main (void)
{
	int i = 0;

	/* Establish a handler for SIGALRM signals. */
	signal(SIGALRM, catch_alarm);

	/* Set an alarm to go off in a little while. */
	alarm(2);

	/* Check the flag once in a while to see when to quit. */
	while (keep_going)
	{
		/* do something */
	       printf ("i = %d\n",++i);
	}

	printf("loop terminated\n");

	return 0;
}
