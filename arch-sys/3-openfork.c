void do_read (char *name, int fd)
{
	char c;
	while (read(fd,&c,1))
	{
		printf("%s: %c\n",name,c);
		sleep(2);
	}
}

void main ()
{
	// Inverting these two lines means that both read accesses
	// will be independent!
	int fd = open("file_a", O_RDONLY);
	int pid = fork();

	if (pid) do_read("parent",fd); else { sleep(1); do_read("child",fd); }
	close(fd);
}
