int foo(int x) {
    printf("I am foo and I have received %d\n", x);
}

int apply(void fn(), int arg) {
    fn(arg);
}

int g ();

int main() {
    apply(foo, 10);
    g = foo;
    apply(g, 20);
}
