int test_throw(int i) {
    if (i == 0) {
        throw Foo(0);
    } else if (i == 1) {
        throw Bar(1);
    }
    return 42;
}

int test_catch(int i) {
    int j = -1;
    try {
        j = test_throw(i);
    } catch (Foo x) {
        printf("Failed n.1 with Foo(%d)\n", x);
    }
    return j;
}

int test_catch_finally (int i) {
    int j = -1;
    try {
        j = test_throw(i);
    } catch (Bar x) {
        printf("Failed n.2 with Bar(%d)\n", x);
    } finally {
        printf("Ended n.2\n");
    }
    return j;
}

int test_finally (int i) {
    int j = -1;
    try {
        j = test_throw(i);
    } finally {
        printf("Ended n.2\n");
    }
    return j;
}

int test_multi_catch (int i) {
    int j = -1;
    try {
        j = test_throw(i);
    } catch (Foo x) {
        printf("Caught Foo(%d)\n", x);
    } catch (Bar y) {
        printf("Caught Bar(%d)\n", y);
        throw Bar(y);
    } catch (Unreachable _) {
        printf("AAAAAAAAAA\n");
    } finally {
        printf("Finally...\n");
    }
    return j;
}

int test_no_error (int i) {
    try {
        printf("Everything is fine.\n");
    } catch (Foo x) {
        printf("Unreachable.\n");
    } finally {
        printf("No error occurred.\n");
    }
    return 10;
}

int test_string () {
    try {
        try {
            throw Foo("Hello, World!");
        } catch (Foo x) {
            printf("Caught %s\n", x);
            throw Foo(x);
        }
    } catch (Foo x) {
        printf("Caught %s again\n", x);
    }
}

int main(int argc, char** argv) {
    switch (atoi(argv[1])) {
        case 1: throw Foo(15); break;
        case 2: test_throw(0); break;
        case 3: test_throw(1); break;
        case 4: test_throw(2); break;
        case 5: test_catch(0); break;
        case 6: test_catch(1); break;
        case 7: test_catch(2); break;
        case 8: test_catch_finally(0); break;
        case 9: test_catch_finally(1); break;
        case 10: test_catch_finally(2); break;
        case 11: test_finally(0); break;
        case 12: test_finally(1); break;
        case 13: test_finally(2); break;
        case 14: test_multi_catch(0); break;
        case 15: test_string(); break;
        case 16: test_multi_catch(1); break;
        case 17: test_multi_catch(2); break;
        case 18: test_no_error(0); break;
    }
    printf("Normal exit\n");
}
