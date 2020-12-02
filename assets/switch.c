int main() {
    int x, y;
    printf("Enter y > "); fflush(stdout);
    scanf("%d", &y);
    x = 0;
    switch (y) {
        case -1: printf("Received y = -1\n");
        case -2:
            printf("Received y = -2 or -1\n");
            printf("Going to break now\n");
            break;
        case 0: return 10;
        case 1: x = 10;
        case 2: printf("x = %d\n", x);
        case 3: {
            printf("Reached 3\n");
            for (; x < 20; x++) {
                printf("%d ", x);
            }
            putchar('\n');
            break;
        }
        default: return 1;
    }
    printf("Broke out of switch\n");
    printf("x = %d\n", x);
}
