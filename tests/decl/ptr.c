int n = 10;

int main(void) {
    int* arr = malloc(n * QSIZE);
    int i;
    for (i = 0; i < n; i++) {
        arr[i] = n - i;
    }
    int cnt = n * QSIZE;
    for (i = 0; i < n; i++) {
        printf("%d ", *(arr+cnt));
        cnt -= QSIZE;
    }
    putchar('\n');
}
