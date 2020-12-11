int main ()
{
	int f = dup(1);		// duplicating stdout

	// both writes end up on stdout
	write(1,"hello world\n",12);
	write(f,"bonjour tout le monde\n",22);
}
