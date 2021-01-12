int main() {
    switch (5) {
        case 1: return;
        case 1: break; //!
    }
    switch (5) {
        case 1: continue; //!
    }
}
