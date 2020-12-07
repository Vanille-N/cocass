#ifndef MCC
#include <stdio.h>
#include <stdlib.h>
#define QSIZE 8
#endif

int cmp (int* a, int* b) {
    if (*a > *b) {
        return 1;
    } else {
        return -1;
    }
}

int main() {
    int* arr;
    int i, len;
    len = 5000;
    arr = malloc(len*QSIZE);
    for (i = 0; i < len; i++) {
        arr[i] = rand() % 10000;
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
