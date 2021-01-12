int main (int argc, char** argv, ...) {} //!

int foo() {
    int* ap;
    va_start(ap); //!
    va_start(101); //!
    va_start(ap, ap); //!
    va_arg(ap); //!
}
