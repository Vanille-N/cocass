int i;
int main() {
    int j;
    i = 5;
    j = 6;
    printf("Yes:\n");
    printf("\ti < j: %d\n", i < j);
    printf("\ti <= j: %d\n", i <= j);
    printf("\ti == i: %d\n", i == i);
    printf("\t!(j <= i): %d\n", !(j <= i));
    printf("\t!(j < i): %d\n", !(j < i));
    printf("\tj > i: %d\n", j > i);
    printf("\tj >= i: %d\n", j >= i);
    printf("\tj != i: %d\n", j != i);
    printf("No:\n");
    printf("\tj < i: %d\n", j < i);
    printf("\tj <= i: %d\n", j <= i);
    printf("\ti == j: %d\n", i == j);
    printf("\t!(i < j): %d\n", !(i < j));
    printf("\t!(i <= j): %d\n", !(i <= j));
    printf("\ti > j: %d\n", i > j);
    printf("\ti >= j: %d\n", i >= j);
    printf("\ti != i: %d\n", i != i);
}
