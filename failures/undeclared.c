int main() {
    int i;
    i = j; //!undeclared//
    j = 1; //!undeclared//
    { int k; }
    i = k; //!undeclared//
    k = 1; //!undeclared//

    arr[0] = 1; //!undeclared//
    i = arr[0]; //!undeclared//
    return 0;
}
