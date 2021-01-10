int cmp(int* a, int* b) {
   return (*a - *b);
}

void assert_increase(int* arr, int len) {
    for (int i = 1; i < len; i++) {
        assert(arr[i-1] < arr[i]);
    }
}

int main(int argc, char** argv) {
    int* items = malloc(QSIZE*argc);
    int key;
    int j = 0;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--key") == 0) {
            key = atol(argv[++i]);
        } else {
            items[j++] = atol(argv[i]);
        }
    }

    try {
        assert_increase(items, j);
    } catch (AssertionFailure) {
        fprintf(stderr, "List is not increasing");
        exit(1);
    }

    int* item = bsearch(&key, items, j, QSIZE, cmp);
    if (item != NULL) {
        printf("Found item = %d at position %d\n", *item, (item - items) / QSIZE);
    } else {
        printf("Item = %d could not be found\n", key);
    }

    free(items);
    return 0;
}
