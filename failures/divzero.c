int main() {
    int x;
    x = 1 / 0; //?division by zero//
    x = 1 / (2 - 2); //?division by zero//
    x = 1 % 0; //?division by zero//
    x = 1 % (2 - 2); //?division by zero//
    x = 1 / (0 * 2 + 2 - 2); //?division by zero//

    x = 1 << -4; //?shift amount//
    x = 56 >> -2; //?shift amount//
}
