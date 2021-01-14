int main() {
    switch (5) {
        case 1: return;
        case 1: break; //!duplicate//
    }
    switch (5) {
        case 1: continue; //!loop//
    }
}
