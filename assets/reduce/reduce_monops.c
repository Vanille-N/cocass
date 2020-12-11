int verify(int x) {
    if (!x) exit(10);
}

int main() {
    int x;
    x = ~10;
    verify(x == ~10);
    x = -12;
    verify(x == -12);
}
