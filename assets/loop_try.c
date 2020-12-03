int foo() {
    int i;
    for (i = 0; 1; i++) {
        try {
            printf("i = %d\n", i);
            switch (i) {
                case 7: throw Seven(NULL);
                case 3: throw Three(NULL);
                case 11: throw Eleven(NULL);
            }
        } catch (Three _) {
            printf("Found 3\n");
        } catch (Seven _) {
            continue;
        } finally {
            printf("Always except 7 (%d).\n", i);
        }
    }
    printf("Never.\n");
}

int main() {
    try {
        foo();
    } catch (Three _) {
        printf("Never.\n");
    } catch (Eleven _) {
        printf("Loop exited at 11.\n");
    }
}
