int main() {
    char* s = malloc(100*BSIZE);
    strcpy(s, "Formatting string: <%s> <%s> <%s>");
    printf(s, s, "foo", "bar");
    putchar('\n');
    free(s);
    fflush(stdout);
}
