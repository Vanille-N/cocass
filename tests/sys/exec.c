int main (int argc, char **argv) {
    if (fork()) {
        wait(NULL);
        printf("[pere] le fils a termine !\n");
    } else {
        execlp("ls", "ls", "-l", NULL);
        printf("Ceci ne devrait pas arriver.\n");
    }
}
