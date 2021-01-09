int main(int argc, char** argv) {
    int* items = malloc(QSIZE*argc);
    int i;
    int mask = ('-' | ('w'<<8));
    int total = 0, count = 0;
    for (i = 1; i < argc; i++) {
        int wht = 1, itm;
        if ((*argv[i] & WORD) == mask) {
            wht = atol(argv[i++]+WSIZE);
        }
        itm = atol(argv[i]);
        count += wht;
        total += wht * itm;
    }
    int mean = (count == 0) ? 0 : total / count;
    printf("%d\n", mean);
    return 0;
}
