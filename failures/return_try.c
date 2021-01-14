int foo() {
    try {
        return 42; //!inside//
    } catch (Wrong _) {
        printf("Should not have caught.\n");
    }
}

int main() {
    foo();
    throw Wrong(NULL);
}
