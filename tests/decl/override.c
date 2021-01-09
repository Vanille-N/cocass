int main() {
    int i = 1;
    int* x = &i;
    int i = 2;
    assert(i == 2);
    assert(*x == 1);
    i++;
    (*x)--;
    assert(i == 3);
    assert(*x == 0);
}
