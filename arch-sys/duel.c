char* id;
char* cible;
int id_cible;

void duel ()
{
	getchar();
	printf("le %s tire sur le %s\n",id,cible);
	kill(id_cible,SIGTERM);
    fflush(stdout);
	while(1);
}

void mort ()
{
	printf("%s: Argh!\n",id);
    fflush(stdout);
	exit(0);
}

int main()
{
	int pb,pm,pt = getpid();

	signal(SIGTERM,mort);

	if (!(pb = fork()))		// le bon
	{
		id = "bon";
		cible = "truand";
		id_cible = pt;
		duel();
	}
	else if (!(pm = fork()))	// le méchant
	{
		id = "mechant";
		cible = "bon";
		id_cible = pb;
		duel();
	}
	else
	{
		id = "truand";
		cible = "mechant";
		id_cible = pm;
		duel();
	}
}
