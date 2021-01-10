int main() {
    int x = 1 ? 42 : 666;
    int y = 0 ? 42 : 666;
    int z = x ? 42 : 666;
    printf("%d %d %d\n", x, y, z);
}
