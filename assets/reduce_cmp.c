int main() {
    printf("Yes:\n");
    printf("\t5 < 6: %d\n", 5 < 6);
    printf("\t5 <= 6: %d\n", 5 <= 6);
    printf("\t5 == 5: %d\n", 5 == 5);
    printf("\t!(6 <= 5): %d\n", !(6 <= 5));
    printf("\t!(6 < 5): %d\n", !(6 < 5));
    printf("\t6 > 5: %d\n", 6 > 5);
    printf("\t6 >= 5: %d\n", 6 >= 5);
    printf("\t6 != 5: %d\n", 6 != 5);
    printf("No:\n");
    printf("\t6 < 5: %d\n", 6 < 5);
    printf("\t6 <= 5: %d\n", 6 <= 5);
    printf("\t5 == 6: %d\n", 5 == 6);
    printf("\t!(5 < 6): %d\n", !(5 < 6));
    printf("\t!(5 <= 6): %d\n", !(5 <= 6));
    printf("\t5 > 6: %d\n", 5 > 6);
    printf("\t5 >= 6: %d\n", 5 >= 6);
    printf("\t5 != 5: %d\n", 5 != 5);
}
