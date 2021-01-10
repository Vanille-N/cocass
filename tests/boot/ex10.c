int main() {
    int y = 7;
    if (true) {
        printf("on est dans le if");
        int y = 3;
    }  else {
        y = 4;
    }
    printf("%d", y);
    return 0;
}
