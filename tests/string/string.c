int strget(char* str, int index) {
    return *(str+index) & BYTE;
}
void strset(char* str, int index, int newval) {
    int arr = str + index;
    *arr = (*arr & ~BYTE) + (newval & BYTE);
}

char* fmt;

int check(char* str) {
    int len, i, val;
    fmt = "str[%*d] = <%c> (%*d)\n";
    len = strlen(str);
    for (i = 0; i < len; i++) {
        val = strget(str, i),
        printf(fmt, 2, i, val, 3, val);
    }
    putchar('\n');
    for (i = 0; i < len; i++) {
        strset(str, i, 'a' + i);
    }
    for (i = 0; i < len; i++) {
        val = strget(str, i),
        printf(fmt, 2, i, val, 3, val);
    }
}

int main(int argc, char** argv) {
    check(argv[0]);
}
