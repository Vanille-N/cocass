void main () {
    // This line goes to standard output as usual.
    printf("This goes to stdout.\n");
    fflush(stdout);

    // We open a new file and make standard output write into it
    int f = open("dump.log", O_WRONLY | O_CREAT | O_TRUNC, 0666);
    dup2(f, 1); // override stdout
    close(f); // we do not need this anymore

    // this line ends up in the file
    printf("This goes to the log.\n");
    fflush(stdout);
}
