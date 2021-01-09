int main(int argc, char** argv) {
    int x = atoi(argv[1]);
    switch (x) {
        case 0:
            int y = 1;
            printf("%d\n", y);
            break;
        case 1:
            // y = 1; // KO
        case 2:
        case 3:
        case 4:
            int y = 2;
            printf("%d\n", y);
    }
}
