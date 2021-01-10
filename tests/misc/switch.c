int main() {
    int y;
    int x = 10;
    printf("Enter y > "); fflush(stdout);
    scanf("%ld", &y);
    switch (y) {
        case -1: printf("Received y = -1\n");
        case -2:
            printf("Received y = -2 or -1\n");
            printf("Going to break now\n");
            break;
        case 0: return 10;
        case 1: x = 20;
        case 2: printf("x = %d\n", x); return;
        case 4: x = 15;
        case 5:
        case 3: {
            printf("Reached 3/4/5\n");
            for (int i = 0; i < x; i++) {
                if (i == 5) continue;
                printf("%d ", i);
                if (i == 13) break;
            }
            putchar('\n');
            break;
        }
        default: return 1;
    }
    printf("Broke out of switch\n");
    printf("x = %d\n", x);
}
