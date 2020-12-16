int main() {
    int x = 1;
    int* y = &x;
    int* z = &*y;
    assert(*z == 1);
    *&x = 3;
    assert(*z == 3);
}
