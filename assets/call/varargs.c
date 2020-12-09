int foo(int x1, int x2, int x3, int x4, ...) {}

int bar(int x1, int x2, int x3, int x4, int x5, int x6, int x7, int x8, ...) {}

int main() {
    // foo(1,2,3); // KO
    foo(1,2,3,4);
    foo(1,2,3,4,5,6);
    foo(1,2,3,4,5,6,7,8,9,10,11,12);
    // bar(1,2,3); // KO
    bar(1,2,3,4,5,6,7,8,9,10,11,12);
}
