// int main (int a, int b, int c) {} // KO
// int main (int argc, char** argv, ...) {}

int foo() {
    int* ap;
    va_init(ap);
    // va_init(101);
    // va_init(ap, ap);
    va_arg(ap);
}
