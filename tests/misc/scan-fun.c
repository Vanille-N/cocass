int foo() {
    int x;
    scanf("%ld", &x);
    printf("You gave me the number %d", x);
    fflush(stdout);
}

int main() {
    foo();
}
