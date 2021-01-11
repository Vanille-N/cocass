int main(int argc, char** argv) {
    char* c = malloc(3);
    while (read(0, c, 3)) {
        write(1, c, 3);
        putchar('\n');
        fflush(stdout);
    }
    free(c);
}
