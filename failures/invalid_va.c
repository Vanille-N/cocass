int main (int argc, char** argv, ...) {} //!may not//

int foo() {
    int* ap;
    va_start(ap); //!non-variadic//
    va_start(101); //!no address//
    va_start(ap, ap); //!exactly one//
    va_arg(ap); //!non-variadic//
}
