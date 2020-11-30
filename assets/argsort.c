int cmp(char** a, char** b) {
    return strcmp(*a, *b);
}

int main(int argc, char** argv) {
    int i;
    qsort(argv, argc, SIZE, cmp);
    for (i = 0; i < argc; i++) {
        printf("%s ", *(argv+i*SIZE));
    }
    putchar('\n');
}
