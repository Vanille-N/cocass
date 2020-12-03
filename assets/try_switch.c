int foo(int i) {
    try {
        switch (i) {
            case 0: break;
            case 1: throw One(NULL);
        }
        printf("Exited switch normally\n");
    } catch (One _) {
        printf("Exited switch with exception\n");
    }
}

int main() {
    foo(0);
    foo(1);
}
