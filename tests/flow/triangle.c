char chr = '*';
int amount = 1;

void line() {
    for (int i = 0; i < amount; i++) {
        putchar(chr);
    }
    putchar('\n');
}

int main(int argc, char** argv) {
    int max = atol(argv[1]);
    for (; amount < max; amount++) {
        line();
    }
}
