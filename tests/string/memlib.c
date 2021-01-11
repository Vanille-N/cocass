int strpref (char* src, char* pref) {
    while (1) {
        if ((*pref & BYTE) == 0) {
            return 0;
        } else if ((*src & BYTE) < (*pref & BYTE)) {
            return 1;
        } else if ((*src & BYTE) > (*pref & BYTE)) {
            return -1;
        }
        pref++;
        src++;
    }
}

void* memchr (void* s, char c, int n) {
    while (n > 0) {
        if ((*s & BYTE) == c) { return s; }
        s++;
        n--;
    }
    return NULL;
}

char* strchr (char* s, char c) {
    while (1) {
        if ((*s & BYTE) == c) { return s; }
        s++;
        if ((*s & BYTE) == 0) { return NULL; }
    }
    return NULL;
}

char* strstr (char* src, char* pat) {
    while (*src != 0) {
        if (strpref(src, pat) == 0) { return src; }
        src++;
    }
}

int main() {
    char* arr = "aaoeu-a/lrcakblcroadksaotelrcdakrcraxracx,.r";
    char* foo = "foo";
    assert(arr+7 == memchr(arr, '/', 50));
    assert(NULL == strchr(arr, 'z'));
    int i = strpref(arr, "aaob");
    assert(-1 == i);
    assert(1 == strpref(arr, "aazzzz"));
    assert(0 == strpref(foo, "foo"));
    assert(arr+8 == strstr(arr, "lrc"));
    return 0;
}
