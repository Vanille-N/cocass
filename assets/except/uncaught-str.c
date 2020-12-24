char* s = "foo";

int main(int argc, char** argv) {
    char* z = "bar";
    switch (atol(argv[1])) {
        case 0: throw Zero("Hello, World");
        case 1: throw One(s);
        case 2: throw Two(z);
    }
}
