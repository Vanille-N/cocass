int main(int argc, char** argv) {
    if (argc > 2) {
        fprintf(stdout, "I have at least two args: %s, %s\n", argv[1], argv[2]);
        if (argc > 3) {
            fprintf(stdout, "I even have one more: %s\n", argv[3]);
        } else {
            fprintf(stdout, "...nevermind, I have only two.\n");
        }
    } else if (argc > 1) {
        fprintf(stdout, "I have just a single argument: %s\n", argv[1]);
    } else {
        fprintf(stdout, "I have no args other than my own name.\n");
    }
}
