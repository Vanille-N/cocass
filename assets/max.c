#ifndef MCC
#include <stdio.h>
#include <stdarg.h>
#endif

int max(int count, ...) {
    va_list ap;
    int best, j, arg;
    va_start(ap, count);
    for (j = 0; j < count; j++) {
        arg = va_arg(ap, int);
        if (j > 0) {
            best = (best > arg) ? best : arg;
        } else {
            best = arg;
        }
    }
    va_end(ap);
    return best;
}

int main(int argc, char** argv) {
    printf("%d == 9\n", max(7, 5,4,9,3,5,0,7));
    printf("%d == 6\n", max(1, 6));
    printf("%d == 8\n", max(2, 4,8));
    printf("%d == 10\n", max(4, 2,5,8,10));
}
