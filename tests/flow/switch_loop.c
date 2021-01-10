int main() {
    for (int i = 0; 1; i++) {
        switch (i) {
            case 1: continue;
            case 3:
            case 5: putchar('\n'); break;
            case 10: return;
            default: printf("%d ", i);
        }
    }
}
