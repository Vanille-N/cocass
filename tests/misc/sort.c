int cmp (int* a, int* b) {
    if (*a > *b) {
        return 1;
    } else {
        return -1;
    }
}

int main(int argc, char** argv) {
    int len = 5000;
    if (argc > 1) len = atol(argv[1]);
    int* arr = malloc(len*QSIZE);
    for (int i = 0; i < len; i++) {
        arr[i] = rand() % 10000;
    }
    for (int i = 0; i < len; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");
    qsort(arr, len, 8, cmp);
    for (int i = 0; i < len; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");
}
