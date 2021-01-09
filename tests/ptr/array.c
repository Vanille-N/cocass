int main() {
    int i, k;
    long* arr;
    i = 0;
    arr = malloc(3*QSIZE);
    arr[i++] = 100;
    arr[i++] = 200;
    arr[i] = arr[0]++;
    fprintf(stdout, "arr[2] = %d ?= 101; ", ++arr[2]);
    fprintf(stdout, "arr[2] = %d ?= 101; ", arr[2]);
    fprintf(stdout, "arr[1] = %d ?= 200; ", arr[1]);
    fprintf(stdout, "arr[0] = %d ?= 101; ", arr[0]);
    k = &arr[1];
    (*k)++;
    fprintf(stdout, "arr[1] = %d ?= %d ?= 201; ", arr[1], *k);
    fflush(stdout);
}
