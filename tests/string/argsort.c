int cmp(void* a, void* b) {
    return strcmp(*a, *b);
}

int main(int argc, char** argv) {
    int i;
    qsort(argv, argc, QSIZE, cmp);
    for (i = 0; i < argc; i++) {
        printf("%s ", *(argv+i*QSIZE));
    }
    putchar('\n');
}
