int W = 6;
int H = 5;

int main() {
    int* arr = malloc(H*QSIZE);
    for (int i = 0; i < H; i++) {
        arr[i] = malloc(W*QSIZE);
        for (int j = 0; j < W; j++) {
            arr[i][j] = i*W + j;
        }
    }
    for (int i = 0; i < H; i++) {
        for (int j = 0; j < W; j++) {
            printf("%d ", arr[i][j]);
        }
        putchar('\n');
    }
}
