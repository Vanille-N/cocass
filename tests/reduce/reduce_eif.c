int main() {
    int x, y, z;
    x = 1 ? 42 : 666;
    y = 0 ? 42 : 666;
    z = x ? 42 : 666;
    printf("%d %d %d\n", x, y, z);
}
