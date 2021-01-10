int bar1(int x, int y) {
    return x + y;
}

int bar2(int x, int y) {
    return y - x;
}

int foo(int x) {
    int z = x;
    z = bar1(x, z);
    z = bar2(x, z);
    return z;
}

int main(int argc, char**argv) {
    int x = foo(argc);
    int y = 3;
    y = foo(y);
    x = x + y;
    return x;
}
