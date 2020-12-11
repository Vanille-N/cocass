int verify(int x) {
    if (!x) exit(1);
}

int main() {
    int x, y;
    x = 3; y = 4;
    verify(x + y == 7);
    verify((x+1) + y == 8);
    verify(x + (y+1) == 8);
    verify(x * y == 12);
    verify((x+1) * y == 16);
    verify(x * (y+1) == 15);
    verify(x - y == -1);
    verify((x+1) - y == 0);
    verify(x - (y+1) == -2);
    x += 3;
    verify(x == 6);
}
