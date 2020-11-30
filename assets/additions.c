int main() {
    int i, j;
    i = malloc(SIZE*3);
    i[0] = 52;
    printf("%d ?= 52\n", *i);
    i[1] = (*i)++ + 2;
    printf("%d ?= 53, %d ?= 54\n", *i,  *(i+SIZE));
    i[2] = ++(*(i+SIZE)) + 2;
    printf("%d ?= 53, %d ?= 55, %d ?= 57\n\n", *i, *(i+SIZE), *(i+2*SIZE));

    free(i);
    j = 1;
    i = &j;
    printf("%d == %d\n", *i, j);
    j = 3;
    printf("%d == %d\n", *i, j);
    j++;
    printf("%d == %d\n", *i, j);
    (*i)++;
    printf("%d == %d\n", *i, j);


    // j += 1; assert(j == 2);
    // i[0] += 1; assert(i[0] == 2);
    // *i += 1; assert(i[0] == 3);
    // j *= 2; assert(j == 4);
    // i[0] *= 2; assert(i[0] == 6);
    // *i *= 2; assert(i[0] == 12);
    // j -= 1; assert(j == 3);
    // i[0] -= 1; assert(i[0] == 11);
    // j = 55;
    // j %= 7; assert(j == 6);
    // i[0] i %= 6; assert(i[0]) == 5);
    // *i %= 3; assert(i[0] == 2);
    // j /= 2; assert(j == 3);
    // i[0] = 20;
    // i[0] /= 2; assert(i[0] == 10);
    // *i /= 2; assert(i[0] == 5);
    // assert(5 ^ 6 == 3);
    // assert(5 & 6 == 4);
    // assert(5 | 6 == 7);
}
