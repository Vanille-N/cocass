#define DISPLAY(X) printf(#X" = %d\n", (X))
#define DECLARE(X) X; printf(#X"\n")

int bin_to_int (char* t, int len) {
    int r = 0;
    int p = 1;
    for (int i = 0; i < len; i++) {
        switch (*(t+i) & BYTE) {
            case '1': r += p; break;
            case '0': break;
            default: throw InvalidBinary(*(t+i) & BYTE);
        }
        p *= 2;
    }
    return r;
}

int main () {
    DECLARE(char* a = "101");
    DISPLAY(bin_to_int(a, 3));
    DISPLAY(bin_to_int(a, 2));
    try {
        DISPLAY(bin_to_int("110f2o", 6));
    } catch (InvalidBinary c) {
        printf("Invalid character '%c' in \"110f2o\"\n", c);
    }
    DISPLAY(bin_to_int("110f2o", 3));
}
