int assert(int x) {
    if (!x) exit(10);
}

int main() {
    int x;
    x = ~10;
    assert(x == ~10);
    x = -12;
    assert(x == -12);
}
