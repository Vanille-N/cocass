int main() {
    int* x;
    x = malloc(16);
    x[0] = 0;
    x[1] = 1;
    printf("%ld\n", (x+1)[0]);
    return 0;
}
