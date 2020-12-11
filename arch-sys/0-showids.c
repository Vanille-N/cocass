void show ()
{
	int u,e,s;
	getresuid(&u,&e,&s);
	printf("uid = %d, euid=%d, suid=%d\n",u,e,s);
}

int main ()
{
	show();

	setuid(0); show();

	setuid(1000); show();

	setuid(0); show();
}
