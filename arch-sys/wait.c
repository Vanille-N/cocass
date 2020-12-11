int main ()
{
	/* The state of parent/child process can be observed, e.g., with ps -u.
 		initially: just the parent process
  		after 5 seconds:  parent and child, both sleeping
		after 15 seconds: child terminates, becomes zombie
		after 25 seconds: parent calls wait(), child disappears
		after 30 seconds: parent terminates
	   The processes can be watched p.ex. using "ps aux | grep wait"
	*/

	printf("Je suis %d, et j'attends quelques secondes...\n",getpid());
	sleep(5);
	if (fork()) {
		int c,result;
		printf("[père] J'attends longtemps...\n");
		sleep(20);
		printf("[père] J'appelle wait maintenant !\n");
		wait(&result);
		c = WEXITSTATUS(result);
		printf("[père] Aie... son dernier mot était %d\n",c);
		sleep(5);
		printf("[père] je termine moi aussi...\n");
		exit(1);
	} else {
		int code = 7;
		printf("[fils] Je suis %d, et mon père est %d\n",
				getpid(),getppid());
		sleep(10);
		printf("[fils] J'en ai marre, je sors avec code %d\n",code);
		exit(code);
	}
}
