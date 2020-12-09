int apply0(int fn()) { return fn(); }
int apply1(int fn(), int x) { return fn(x); }
int apply2(int fn(), int x, int y) { return fn(x, y); }
int apply1bis(int fn(), int x) { return apply1(fn, x); }

int foo0() { return 42; }
int bar0() { return 666; }
int foo1(int x) { return x+10; }
int bar1(int x) { return x/2; }
int foo2(int x, int y) { return x + y; }
int bar2(int x, int y) { return x - y; }

int main() {
    printf("foo1(5) = %d ?= 15\n", apply1(foo1, 5));
    printf("foo1(bar1(5)) = %d ?= 12\n", apply1bis(foo1, apply1bis(bar1, 5)));
    printf("foo2(foo0(), bar1(bar0()) = %d ?= 375\n", apply2(foo2, apply0(foo0), apply1bis(bar1, apply0(bar0))));
}
