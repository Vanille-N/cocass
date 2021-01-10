#define FILE char

int main (int argc, char **argv) {
    for (int i = 1; i < argc; i++) {
        FILE* f = fopen(argv[i], "r");
        int c;
        while ((c = fgetc(f)) != EOF) {
	        fputc(c, stdout);
            // usleep(1000);
        }
        fclose(f);
    }
    fflush(stdout);
    exit(0);
}
