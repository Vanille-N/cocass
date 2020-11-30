int main() {
    int i, j, k;

    if ((i = 3) > (i = 4)) {}
    printf("i is %d, should be 4\n\n", i);

    if ((i = 3) >= (i = 4)) {}
    printf("i is %d, should be 4\n\n", i);

    // k = malloc(3*SIZE);
    // k[0] = 100; k[1] = 1; k[2] = 1000;
    // i = 1;
    // k[i++] += 1;
    // printf("i is %d, should be 2\n", i);
    // printf("k is [%d;%d;%d], should be [100, 2, 1000]");
}
