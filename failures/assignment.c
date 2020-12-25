int main() {
    // 1 = 1; // KO
    int x;
    (x+1) = 1; // KO
    -x = 1; // KO
    (x = 1) = 1; // KO
    (1 < 2) = 1; // KO
    "foo" = 1; // KO
    foo() = 1;
    (1 ? x : x) = 1; // KO
    (x = 1, x = 2) = 1; // KO
}
