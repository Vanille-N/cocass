int foo() {}
int bar(int a) {}
int baz(int a, int b) {}

int main() {
    foo();
    foo(1); //?
    foo(1, 1); //?
    bar(); //?
    bar(1);
    bar(1, 2); //?
    baz(); //?
    baz(1); //?
    baz(1, 2);
    malloc(); //?
    malloc(0, 1, 2); //?
    printf(); //?
    fprintf(stdout); //?
    quux(); //?
}
