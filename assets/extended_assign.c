int main() {
    int i, j;
    i = malloc(SIZE*3);
    j = 1;
    i[0] = 5; i[1] = 7; i[2] = 3;

    j += 1;         printf("%d ?= 2\n", j);
    i[0] += 1;      printf("%d ?= 6\n", i[0]);
    *i += 1;        printf("%d ?= 7\n\n", *i);

    j *= 2;         printf("%d ?= 4\n", j);
    i[0] *= 2;      printf("%d ?= 14\n", i[0]);
    *i *= 2;        printf("%d ?= 28\n\n", *i);

    j -= -15;       printf("%d ?= 11\n", j);
    i[0] -= 1;      printf("%d ?= 27\n", i[0]);
    *i -= 2;        printf("%d ?= 25\n\n", *i);

//     j /= 2;         printf("%d ?= 5\n", j);
//     i[0] /= 5;      printf("%d ?= 5\n", i[0]);
//     *i /= 2;        printf("%d ?= 2\n\n", *i);
//
//     j %= 3;         printf("%d ?= 2\n", j);
//     i[0] = 10;
//     i[0] %= 4;      printf("%d ?= 2\n", i[0]);
//     *i = 15;
//     *i %= 6;        printf("%d ?= 3\n\n", *i);
//
//     j >>= 2;        printf("%d ?= 8\n", j);
//     i[0] >>= 1;     printf("%d ?= 6\n", i[0]);
//     *i >>= 2;       printf("%d ?= 24\n\n", *i);
//
//     j <<= 1;        printf("%d ?= 4\n", j);
//     i[0] <<= 1;     printf("%d ?= 12\n", i[0]);
//     *i <<= 1;       printf("%d ?= 6\n\n", *i);
//
//     j |= 1;         printf("%d ?= 5\n", j);
//     i[0] |= 5;      printf("%d ?= 7\n", i[0]);
//     *i |= 9;        printf("%d ?= 13\n\n", *i);
//
//     j &= 3;         printf("%d ?= 1\n", j);
//     i[0] &= 11;     printf("%d ?= 9\n", i[0]);
//     *i &= 7;        printf("%d ?= 1\n\n", *i);
//
//     j ^= 5;         printf("%d ?= 4\n", j);
//     i[0] ^= 2;      printf("%d ?= 3\n", i[0]);
//     *i ^= 5;        printf("%d ?= 6\n", *i);
}
