int main() {
    int i;

    if ((i = 3) > (i = 4)) {}
    printf("i is %d ?= 3\n", i);
    if ((i = 3) >= (i = 4)) {}
    printf("i is %d ?= 3\n", i);
    if ((i = 3) < (i = 4)) {}
    printf("i is %d ?= 3\n", i);
    if ((i = 3) <= (i = 4)) {}
    printf("i is %d ?= 3\n", i);
    if ((i = 3) == (i = 4)) {}
    printf("i is %d ?= 3\n", i);
}
