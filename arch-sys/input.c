int x;

void foo ()
{
		sleep(1);
}

int main(int argc,char **argv)
{
        x = atoi(argv[1]);
	while (1) { foo(); }
}
