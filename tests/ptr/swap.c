#define DISPLAY(X) printf(#X" = %d\n", (X));0

void swap (int* a, int* b) {
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

int main () {
    int a = 5;
    int b = 10;
    DISPLAY(a);
    DISPLAY(b);
    swap(&a, &b);
    DISPLAY(a);
    DISPLAY(b);
}
