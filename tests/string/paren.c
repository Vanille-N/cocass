int bien_parentesee (char* str) {
    for (int cnt = 0;;) { // cnt counts the number of '(' more than ')'
        switch (*str++ & BYTE) {
            case 0: return !cnt; // cnt != 0 iff there is an unclosed paren
            case '(': cnt++; break; // open paren
            case ')':
                if (cnt) {
                    cnt--; break; // close paren
                } else {
                    return 0; // unopened paren
                }
        }
    }
}

int main (int argc, char** argv) {
    for (int i = 1; i < argc; i++) {
        printf("%s -> %d\n", argv[i], bien_parentesee(argv[i]));
    }
}
