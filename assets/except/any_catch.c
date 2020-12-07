int main(int argc, char** argv) {
    int i;
    i = atoi(argv[1]);
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
    } finally {
        printf("Exit.\n");
    }
}
