void main ()
{
	// This line goes to standard output as usual.
	write(1,"hello world\n",12);

	// We open a new file and make standard output write into it
	int f = open("myfile.txt",O_WRONLY | O_CREAT,0666);
	dup2(f,1);	// override stdout
	close(f);	// we do not need this anymore

	// this line ends up in the file
	printf("bonjour tout le monde\n");
}
