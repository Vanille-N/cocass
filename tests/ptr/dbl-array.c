int W = 6;
int H = 5;

int main() {
    int* arr = malloc(H*QSIZE);
    int i;
    for (i = 0; i < H; i++) {
        arr[i] = malloc(W*QSIZE);
        int j;
        for (j = 0; j < W; j++) {
            arr[i][j] = i*W + j;
        }
    }
    for (i = 0; i < H; i++) {
        int j;
        for (j = 0; j < W; j++) {
            printf("%d ", arr[i][j]);
        }
        putchar('\n');
    }
}
