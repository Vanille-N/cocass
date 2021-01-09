int assert_eq(int i, int j) {
    try {
        assert(i == j);
    } catch (AssertionFailure _) {
        printf("%d is not equal to %d\n", i, j);
    }
}

int main(int argc, char** argv) {
    int i = atol(argv[1]);
    int j = atol(argv[2]);
    assert_eq(i, j);
}
