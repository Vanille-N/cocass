int strget(char* str, int index) {
    int val, arr;
    arr = str + index;
    val = arr[0];
    return val % 256;
}
int strset(char* str, int index, int newval) {
    int val, arr;
    arr = str + index;
    arr[0] = arr[0] + (newval % 256) - (arr[0] % 256);
}

int* fmt;

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
