void strset(char* str, int index, int newval) {
    int arr = str + index;
    *(str+index) = (*(str+index) & ~BYTE) + (newval & BYTE);
}

int main() {
    char* s = malloc(100);
    for (int i = 0; i < 100; i++) strset(s, i, i);
    printf("0x%08X\n", *(s+BSIZE));
    printf("0x%08X\n", *(s+WSIZE));
    printf("0x%08X\n", *(s+DSIZE));
    printf("0x%08X\n", *(s+QSIZE));
    printf("0x%08X\n", *(s+2*BSIZE));
    printf("0x%08X\n", *(s+BSIZE*2));
    printf("0x%08X\n", *(s+2*WSIZE));
    printf("0x%08X\n", *(s+WSIZE*2));
    printf("0x%08X\n", *(s+2*DSIZE));
    printf("0x%08X\n", *(s+DSIZE*2));
    printf("0x%08X\n", *(s+2*QSIZE));
    printf("0x%08X\n", *(s+QSIZE*2));
    *(s+BSIZE) += 1;
    *(s+WSIZE) += 1;
    *(s+DSIZE) += 1;
    *(s+QSIZE) += 1;
    *(s+2*BSIZE) += 1;
    *(s+BSIZE*2) += 1;
    *(s+2*WSIZE) += 1;
    *(s+WSIZE*2) += 1;
    *(s+2*DSIZE) += 1;
    *(s+DSIZE*2) += 1;
    *(s+2*QSIZE) += 1;
    *(s+QSIZE*2) += 1;
    printf("0x%08X\n", *(s+BSIZE));
    printf("0x%08X\n", *(s+WSIZE));
    printf("0x%08X\n", *(s+DSIZE));
    printf("0x%08X\n", *(s+QSIZE));
    printf("0x%08X\n", *(s+2*BSIZE));
    printf("0x%08X\n", *(s+2*WSIZE));
    printf("0x%08X\n", *(s+2*DSIZE));
    printf("0x%08X\n", *(s+2*QSIZE));
    *(s+BSIZE) = 1;
    *(s+WSIZE) = 1;
    *(s+DSIZE) = 1;
    *(s+QSIZE) = 1;
    *(s+2*BSIZE) = 1;
    *(s+BSIZE*2) = 1;
    *(s+2*WSIZE) = 1;
    *(s+WSIZE*2) = 1;
    *(s+2*DSIZE) = 1;
    *(s+DSIZE*2) = 1;
    *(s+2*QSIZE) = 1;
    *(s+QSIZE*2) = 1;
}
