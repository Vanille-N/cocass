int main() {
    printf("1. for                   ");
    for (int i = 0; i < 10; i++) {
        printf("%d ", i);
    }
    printf("\n2. one-line for          ");
    for (int i = 0; i < 10; i++) printf("%d ", i);
    printf("\n3. for no-inc            ");
    for (int i = 0; i < 10;) {
        printf("%d ", i);
        i++;
    }
    printf("\n4. for no-init           ");
    int i = 0;
    for (; i < 10; i++) {
        printf("%d ", i);
    }
    printf("\n5. for only-cond         ");
    int i = 0;
    for (; i < 10;) {
        printf("%d ", i);
        i++;
    }
    printf("\n6. while                   ");
    int i = 1;
    while (i % 10 != 0) {
        printf("%d ", i);
        i++;
    }
    printf("\n7. do-while              ");
    int i = 0;
    do {
        printf("%d ", i);
        i++;
    } while (i % 10 != 0);
    printf("\n8. one-line while          ");
    int i = 1;
    while (i % 10 != 0) printf("%d ", i++);
    printf("\n9. one-line do-while     ");
    int i = 0;
    do printf("%d ", i); while (++i % 10 != 0);
}
