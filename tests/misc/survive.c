void ignore_sigint() {
    printf("You can't kill me !\n");
}

int main() {
    printf("I am %d\n", getpid());
    signal(SIGINT, ignore_sigint);
    while (true) {
        usleep(1000);
    }
}
