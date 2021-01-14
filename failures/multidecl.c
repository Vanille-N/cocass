int main(int argc, char** argc) {} //!twice//

int foo() {}
int bar() {}
int baz() {}
int foo() {} //!redefinition//
int foo() {} //!redefinition//

int main() {} //!redefinition//

int x;
int foo; //!redefinition//
int x; //!redefinition//
int main; //!redefinition//

int va_arg; //!reserved//
int assert; //!reserved//
int va_start; //!reserved//
