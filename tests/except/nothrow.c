int main() {
    try {
        printf("This may not fail, despite the try block.\n");
    } catch (Unreachable _) {
        printf("Never.\n");
    } finally {
        printf("Always.\n");
    }
}
