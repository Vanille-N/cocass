int main (int argc, char **argv)
{
	if (fork()) {

		// Parent process: wait till child terminates (ignoring
		// its result), then print "terminated" and exit.
		wait(NULL);
		printf("[pere] le fils a termine !\n");

	} else {

		// Child process

		//printf("[fils] Merci de taper <retour>\n");
		//getchar();

		// The following two variants (execlp/execvp) are equivalent,
		// where the arguments start with the "zeroth" argument -
		// normally the name of the programme itself.

		execlp("ls", "ls", "-l", NULL);

		// version alternative :
		// char *args[] = { "ls", "-l", NULL };
		// execvp("ls",args);

		// The following command is reached only when exec() fails.
		printf("Ceci ne devrait pas arriver.\n");

	}
}
