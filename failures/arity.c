int foo() {}
int bar(int a) {}
int baz(int a, int b) {}

int main() {
    foo();
    foo(1); //?arity//
    foo(1, 1); //?arity//
    bar(); //?arity//
    bar(1);
    bar(1, 2); //?arity//
    baz(); //?arity//
    baz(1); //?arity//
    baz(1, 2);
    malloc(); //?arity//
    malloc(0, 1, 2); //?arity//
    printf(); //?arity//
    fprintf(stdout); //?arity//
    quux(); //?unknown//
}
