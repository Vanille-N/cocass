int mstrlen (char * str) {
    int i = -1;
    while (*(str+(++i)) & BYTE) {}
    return i;
}

int mstrcmp (char * lt, char * rt) {
    while ((*lt & BYTE) && ((*lt & BYTE) == (*rt & BYTE))) {
        lt++; rt++;
    }
    return (*lt & BYTE) - (*rt & BYTE);
}

void mstrcpy (char* src, char* dest) {
    while ((*dest &= ~BYTE), (*dest++ |= (*src++ & BYTE)) & BYTE) {}
    return --dest;
}

int main (int argc, char** argv) {
    if (argc == 2) {
        printf("%d\n", mstrlen(argv[1]));
        return 0;
    } else if (argc == 3) {
        printf("%d\n", mstrcmp(argv[1], argv[2]));
        return 0;
    } else if (argc == 4) {
        char* s = malloc(100);
        char* tmp = s;
        tmp = mstrcpy(argv[1], tmp);
        tmp = mstrcpy(argv[2], tmp);
        tmp = mstrcpy(argv[3], tmp);
        printf("%s\n", s);
        free(s);
        return 0;
    } else {
        return 1;
    }
}
