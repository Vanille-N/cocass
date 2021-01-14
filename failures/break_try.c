int foo() {
    int i;
    for (i = 0; i < 10; i++) {
        try {
            break; //!outside//
        } catch (Wrong _) {
            printf("Should not have caught.\n");
        }
    }
    throw Wrong(NULL);
}

int main() {
    foo();
}
