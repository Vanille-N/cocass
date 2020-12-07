int foo() {
    int i;
    try {
        for (i = 0; i < 10; i++) {
            if (i == 5) {
                break; // OK
                // continue; // OK
                // return; // KO
                // return 1; // KO
            }
            printf("i = %d\n", i);
            if (i == 7) {
                throw Exit(NULL);
            }
        }
    }
    return 0;
}

int main() {
    return foo();
}
