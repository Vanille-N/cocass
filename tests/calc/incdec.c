int main() {
    int* arr = malloc(10*QSIZE);
    for (int i = 0; i < 10; i++) {
        arr[i] = i;
    }
    int i = 0;
    while (i < 10) {
        --arr[i++];
    }
    for (i = 0; i < 10; i++) {
        printf("%d\n", arr[i]);
    }
}
