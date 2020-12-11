int main()
{
	int pg,pb,pu;
	if (!(pg = fork()))
		{ sleep(1); while(1) { printf("good\n"); sleep(3); } }
	else if (!(pb = fork()))
		{ sleep(2); while(1) { printf("bad\n"); sleep(3); } }
	else if (!(pu = fork()))
		{ sleep(3); while(1) { printf("ugly\n"); sleep(3); } }
	else
	{
		setpgid(pb,pb);
		setpgid(pu,pb);
		printf("type <enter> to kill the bad and ugly\n");
		getchar();
		kill(-pb,SIGTERM);
		while(1) { sleep(10); }
	}
}
