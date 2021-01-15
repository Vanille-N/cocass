void ignore_sigint() {
    printf("You can't kill me !\n");
    fflush(stdout);
}

int main() {
    printf("I am %d\n", getpid());
    fflush(stdout);
    signal(SIGINT, ignore_sigint);
    while (true) {
        usleep(1000);
    }
}
