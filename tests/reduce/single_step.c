int main() {
    int x = 3, y = 4;
    assert(x + y == 7);
    assert((x+1) + y == 8);
    assert(x + (y+1) == 8);
    assert(x * y == 12);
    assert((x+1) * y == 16);
    assert(x * (y+1) == 15);
    assert(x - y == -1);
    assert((x+1) - y == 0);
    assert(x - (y+1) == -2);
    x += 3;
    assert(x == 6);
}
