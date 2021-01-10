int mean(int* items, int len) {
    int total = 0;
    for (int i = 0; i < len; i++) {
        total += items[i];
    }
    if (len > 0) {
        return (total / len);
    } else {
        return 0;
    }
}

int main(int argc, char** argv) {
    int* items = malloc(QSIZE*argc);
    for (int i = 1; i < argc; i++) {
        items[i-1] = atol(argv[i]);
    }
    printf("%d\n", mean(items, argc-1));
}
