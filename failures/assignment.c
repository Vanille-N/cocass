int foo() {}

int main() {
    1 = 1; //!lvalue|address//
    int x, y;
    (x+1) = 1; //!lvalue//
    -x = 1; //!lvalue//
    (x = 1) = 1; //!lvalue//
    (1 < 2) = 1; //!lvalue|address//
    "foo" = 1; //!lvalue|addressed//
    foo() = 1; //!lvalue//
    (x ? y : x) = 1; //!lvalue//
    (x = 1, x = 2) = 1; //!lvalue//
}
