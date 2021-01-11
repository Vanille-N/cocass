#define MAXTEST 1000
#define MAXVAL 1000000

int syracuse() {
    for (int nombre = 1; nombre <= MAXTEST; nombre++) {
        int vol = nombre;
        int i;
        for (i = 0; i <= MAXVAL; i++) {
            if (vol == 1) break;
            if (vol >= MAXVAL) break;
            if (vol & 1) {
                vol = 3 * vol + 1;
            } else {
                vol = vol / 2;
            }
        }
        if (i == MAXVAL + 1) return 1;
        if (vol == 1) {
            printf("Ok %d\n", nombre);
        } else {
            printf("Not found %d\n", nombre);
        }
    }
    return 0;
}

int main() {
    if (syracuse()) {
        printf("Contre-exemple trouve !\n");
    }
    return 0;
}
