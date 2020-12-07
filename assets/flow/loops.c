int main() {
    int i;
    printf("1. for                   ");
    for (i = 0; i < 10; i++) {
        printf("%d ", i);
    }
    printf("\n2. one-line for          ");
    for (i = 0; i < 10; i++) printf("%d ", i);
    printf("\n3. for no-inc            ");
    for (i = 0; i < 10;) {
        printf("%d ", i);
        i++;
    }
    printf("\n4. for no-init           ");
    i = 0;
    for (; i < 10; i++) {
        printf("%d ", i);
    }
    printf("\n5. for only-cond         ");
    i = 0;
    for (; i < 10;) {
        printf("%d ", i);
        i++;
    }
    printf("\n6. while                   ");
    i = 1;
    while (i % 10 != 0) {
        printf("%d ", i);
        i++;
    }
    printf("\n7. do-while              ");
    i = 0;
    do {
        printf("%d ", i);
        i++;
    } while (i % 10 != 0);
    printf("\n8. one-line while          ");
    i = 1;
    while (i % 10 != 0) printf("%d ", i++);
    printf("\n9. one-line do-while     ");
    i = 0;
    do printf("%d ", i); while (++i % 10 != 0);
}
