int test_throw(int i) {
    if (i == 0) {
        throw Foo(0);
    } else if (i == 1) {
        throw Bar(1);
    }
    return 42;
}

// int test_catch(int i) {
//     int j;
//     try {
//         throw Bar(7);
//         // j = test_throw(i);
//         // j = 10;
//     } catch (Foo x) {
//         printf("Failed n.1 with Foo(%d)\n", x);
//     }
//     return j;
// }
//
// int test_catch_finally (int i) {
//     try {
//         return test_throw(i);
//     } catch (Bar x) {
//         printf("Failed n.2 with Bar(%d)\n", x);
//         // if (x == 1) { throw Bar(5); }
//     } finally {
//         printf("Ended n.2\n");
//         // throw Baz(5);
//     }
// }
//
// int test_finally (int i) {
//     try {
//         return test_throw(i);
//     } finally {
//         printf("Ended n.2\n");
//     }
// }
//
int test_multi_catch (int i) {
    int i;
    try {
        i = test_throw(i);
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
    return i;
}
//
// int test_no_error (int i) {
//     try {
//         printf("Everything is fine.\n");
//     } catch (Foo x) {
//         printf("Unreachable.\n");
//     } finally {
//         printf("No error occurred.\n");
//     }
//     return 10;
// }

int test_string () {
    try {
        try {
            throw Foo("Hello, World!");
        } catch (Foo x) {
            printf("Caught %s\n", x);
            throw Foo(x);
        }
        // throw Baz("Nope");
    } catch (Foo x) {
        printf("Caught %s again\n", x);
        throw Foo(x);
    }
}

int main() {
    // throw Foo(15);
    // test_throw(0);
    // test_throw(1);
    // test_throw(2);
    // OK
    // test_catch(0);
    // test_catch(1);
    // test_catch(2);
    // test_catch_finally(1);
    // test_catch_finally(1);
    // test_catch_finally(2);
    // test_finally(0);
    // test_finally(1);
    // test_finally(2);
    // test_multi_catch(0);
    test_string();
    // test_multi_catch(1);
    // test_multi_catch(2);
    // test_no_error(0);
    printf("Normal exit");
}
