int main () {
    signal(SIGINT, SIG_IGN);
	while (1) {
		printf("je suis là et je m'appelle %d\n",getpid());
		sleep(1);
	}
}
