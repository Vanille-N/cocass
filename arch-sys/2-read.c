int main()
{
	char* c = malloc(3);
	int f = open("file_a",O_RDONLY);
	while (read(0,c,3))
	{
		write(1,c,3);
		fflush(stdout);
		sleep(3);
	}
    free(c);
}
