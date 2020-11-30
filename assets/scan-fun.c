int foo() {
    int x;
    x = malloc(SIZE);
    scanf("%d", x);
    printf("You gave me the number %d", x[0]);
    fflush(stdout);
}

int main() {
    foo();
}
