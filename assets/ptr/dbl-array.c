int main() {
    int* arr = malloc(3*QSIZE);
    int i;
    for (i = 0; i < 3; i++) {
        int* k = malloc(2*QSIZE);
        k[0] = 2*i+1;
        k[1] = 2*i+2;
        arr[i] = k;
    }
    arr[0][0]++;
    printf("[ %d %d ]\n", arr[0][0], arr[0][1]);
    printf("[ %d %d ]\n", arr[1][0], arr[1][1]);
    printf("[ %d %d ]\n", arr[2][0], arr[2][1]);
}
