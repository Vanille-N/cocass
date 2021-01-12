int main() {
    int i;
    i = j; //!
    j = 1; //!
    { int k; }
    i = k; //!
    k = 1; //!

    arr[0] = 1; //!
    i = arr[0]; //!
    return 0;
}
