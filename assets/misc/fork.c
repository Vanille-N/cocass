int main() {
    if (fork()) {
        printf("I am parent\n");
    } else {
        printf("I am child\n");
    }
}
