int main() {
    int* arr;
    int i;
    arr = malloc(10*SIZE);
    for (i = 0; i < 10; i++) {
        arr[i] = i;
    }
    i = 0;
    while (i < 10) {
        --arr[i++];
    }
    for (i = 0; i < 10; i++) {
        printf("%d\n", arr[i]);
    }
}
