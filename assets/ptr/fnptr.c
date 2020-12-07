int foo(int x) {
    printf("I am foo and I have received %d\n", x);
}

int apply(int* fn, int arg) {
    fn(arg);
}

int main() {
    apply(foo, 10);
}
