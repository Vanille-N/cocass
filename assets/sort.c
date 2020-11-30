#ifndef MCC
#include <stdio.h>
#include <stdlib.h>
#define SIZE 8
#endif

int cmp (int* a, int* b) {
    if (a[0] > b[0]) {
        return 1;
    } else {
        return -1;
    }
}

int main() {
    int* arr;
    int i, len;
    len = 50;
    arr = malloc(len*SIZE);
    for (i = 0; i < len; i++) {
        arr[i] = rand() % 100;
    }
    for (i = 0; i < len; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");
    qsort(arr, len, 8, cmp);
    for (i = 0; i < len; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");
}
