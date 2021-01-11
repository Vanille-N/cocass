// exit codes :: arguments
#define WR_OPT 1 // invalid option
#define WR_ARG 2 // badly formatted argument
#define WR_FILE 3 // file does not exist

// exit codes :: syscalls
#define ERR_RD 101 // read failed
#define ERR_OP 102 // open failed
#define ERR_SK 103 // lseek failed

// error handlers
#define VERIFY_READ(X) { \
    if ((X) == -1) { \
        perror("Failed to read. "); \
        exit(ERR_RD); \
    } \
}

#define VERIFY_OPEN(X) { \
    if ((X) == -1) { \
        perror("Failed to open. "); \
        exit(ERR_OP); \
    } \
}

#define VERIFY_LSEEK(X) { \
    if ((X) == -1) { \
        perror("Failed to seek. "); \
        exit(ERR_SK); \
    } \
}

#define NB_THREADS 4
#define BUFSIZE (64 * 1024)
#define SEEK_END 2
#define R_OK 4
#define SEEK_CUR 1

void invalid (char* msg, int retcode) {
    printf(msg);
    printf("usage: mwc [-l|-w|-c] FILE\n");
    printf("  count (l)ines, (w)ords, (c)haracters in FILE (default -w)\n");
    exit(retcode);
}

int main (int argc, char** argv) {
    if (argc == 1) invalid("Not enough arguments\n", WR_ARG);
    char* file = NULL;
    char mode = 0;
    for (int i = 1; i < argc; i++) {
        if ((*argv[i] & BYTE) == '-') { // treat as an argument
            if (mode != 0) invalid("Too many optional arguments\n", WR_OPT); // already have an option
            switch (*(argv[i]+1) & BYTE) {
                case 'w': case 'c': case 'l':
                    mode = *(argv[i]+1) & BYTE;
                    break;
                default: invalid("Invalid optional argument\n", WR_OPT); // unknown option: not w/l/c
            }
            if ((*(argv[i]+2) & BYTE) != 0) invalid("Optional argument too long\n", WR_OPT); // option is not -w/-l/-c
        } else {
            if (file != NULL) invalid("Too many positional arguments\n", WR_ARG);
            file = argv[i];
        }
    }
    if (file == NULL) invalid("Not enough positional arguments\n", WR_ARG);
    if (mode == 0) mode = 'w'; // default is -w

    if (access(file, R_OK) == 0) { // thanks to this we don't have to handle errors for open()
        switch (mode) {
            case 'c': {
                int n = count_bytes(file);
                printf("%d %s\n", n, file);
                break;
            }
            case 'w': {
                int n = dispatch(file, count_words);
                printf("%d %s\n", n, file);
                break;
            }
            case 'l': {
                int n = dispatch(file, count_lines);
                printf("%d %s\n", n, file);
                break;
            }
        }
    } else {
        invalid("File does not exist\n", WR_FILE);
    }
    return 0;
}

char* z_file;
int* z_start, z_end, z_count;

int* counters;

int dispatch (char* file, void* counter) {
    // open to determine length -> distribution of ranges
    int fd = open(file, O_RDONLY, 0444);
    VERIFY_OPEN(fd);
    int length = lseek(fd, 0, SEEK_END);
    close(fd);

    // launch threads
    z_file = file;
    z_start = malloc(QSIZE*NB_THREADS);
    z_end = malloc(QSIZE*NB_THREADS);
    z_count = malloc(QSIZE*NB_THREADS);
    counters = malloc(QSIZE*NB_THREADS);
    for (int i = 0; i < NB_THREADS; i++) {
        z_start[i] = (i * length) / NB_THREADS;
        z_end[i] = ((i+1) * length) / NB_THREADS;
        pthread_create(&counters[i], NULL, counter, i);
    }

    // terminate threads and calculate sum
    int sum = 0;
    for (int i = 0; i < NB_THREADS; i++) pthread_join(counters[i], NULL);
    for (int i = 0; i < NB_THREADS; i++) sum += z_count[i];
    return sum;
}

int count_bytes (char* file) {
    int fd = open(file, O_RDONLY, 0444);
    int pos = lseek(fd, 0, SEEK_END);
    VERIFY_LSEEK(pos);
    close(fd);
    return pos;
}

// A line is any number of characters followed by a '\n'
void* count_lines (int id) {
    // open file and init variables
    int fd = open(z_file, O_RDONLY, 0444);
    int pos = lseek(fd, z_start[id], SEEK_CUR);
    VERIFY_LSEEK(pos);
    char* buf = malloc(BUFSIZE);
    int length = z_end[id] - z_start[id];
    int count = 0;

    // count by BUFSIZE intervals
    while (length > 0) {
        int iter = BUFSIZE < length ? BUFSIZE : length;
        int err = read(fd, buf, iter);
        VERIFY_READ(err);
        for (int i = 0; i < iter; i++) {
            if ((*(buf+i) & BYTE) == '\n') count++;
        }
        length -= BUFSIZE;
    }

    // terminate
    close(fd);
    free(buf);
    z_count[id] = count;
    pthread_exit(NULL);
}

int is_endword (char c) {
    switch (c) {
        case ' ': case '\t': case '\n': return 1;
        default: return 0;
    }
}

// A word is any non-is_endword() followed by a is_endword()
void* count_words (int id) {
    // open file and init variables
    int fd = open(z_file, O_RDONLY, 0444);
    int pos = lseek(fd, z_start[id], SEEK_CUR);
    VERIFY_LSEEK(pos);
    char* buf = malloc(BUFSIZE);
    int length = z_end[id] - z_start[id];
    int count = 0;
    int prev_blank = 1;

    // count by BUFSIZE intervals
    while (length > 0) {
        int iter = BUFSIZE < length ? BUFSIZE : length;
        int err = read(fd, buf, iter);
        VERIFY_READ(err);
        for (int i = 0; i < iter; i++) {
            if (is_endword(*(buf+i) & BYTE)) {
                if (!prev_blank) {
                    prev_blank = 1;
                    count++;
                }
            } else {
                prev_blank = 0;
            }
        }
        length -= BUFSIZE;
    }
    if (!prev_blank) {
        // last character of the zone could be the end of a word
        char c = 0;
        read(fd, &c, 1);
        c &= BYTE;
        // we don't check here because failure means end of file,
        // which is detected by (c == 0).
        if (is_endword(c) || c == 0) {
            count++;
        }
    }

    // terminate
    close(fd);
    free(buf);
    z_count[id] = count;
    pthread_exit(NULL);
}
