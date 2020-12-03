int main() {
    int i;
    i = 2;
    try {
        switch (i) {
            case 0: throw Zero(NULL);
            case 1: throw One(NULL);
            case 2: throw Two(NULL);
        }
    } catch (Zero _) {
        printf("Zero\n");
    } catch (_ _) {
        printf("Something else\n");
    }
}
