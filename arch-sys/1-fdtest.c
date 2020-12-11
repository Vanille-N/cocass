int main ()
{
	int a = open("file_a",O_RDONLY);
	int b = open("file_b",O_RDONLY);
	int c = open("file_c",O_WRONLY);
	int d = dup(a);
	int e = creat("file_e",0666);
	close (c);
	int f = open("file_a",O_WRONLY);

	printf("a=%d b=%d c=%d d=%d e=%d f=%d\n",a,b,c,d,e,f);

}
