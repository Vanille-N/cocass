#ifndef MCC
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#define SIZE 8
#define int long
#endif

int max;

int choose() {
    return rand() % max;
}

int strindex(char* str, int index) {
    int base, loc, val;
    base = index / SIZE;
    loc = index % SIZE;
    val = str[base];
    while (loc--) {
        val = val / 256;
    }
    return val % 256;
}

int isnumber(char* str) {
    int len, i, val;
    len = strlen(str);
    for (i = 0; i < len; i++) {
        val = strindex(str, i);
        if (!('0' <= val && val <= '9')) {
            return false;
        }
    }
    return true;
}


int compare(int guess, int real) {
    if (guess < 0) {
        printf("The number has to be positive, are you even trying ?\n");
    } else if (guess > max) {
        printf("Come on, I said it wouldn't be any greater than %d...\n", max);
    } else if (guess == real) {
        printf("You guessed it! Good job.\n");
        return true;
    } else if (guess < real) {
        printf("A bit bigger...\n");
    } else {
        printf("Slightly smaller...\n");
    }
    return false;
}

int play() {
    int real, found;
    int* guess;
    guess = malloc(SIZE);
    real = choose();
    found = false;
    printf("I want to make you guess a number.\n");
    printf("It's between 0 and %d.\n", max);
    while (!found) {
        printf("   > ");
        scanf("%d", guess);
        found = compare(guess[0], real);
    }
    free(guess);
}

int check(char* str) {
    int len, i, val;
    len = strlen(str);
    for (i = 0; i < len; i++) {
        val = strindex(str, i),
        printf("str[%d] = <%c> (%d)\n", i, val, val);
    }
}

int main(int argc, char** argv) {
    if (argc > 1 && isnumber(argv[1])) {
        max = atol(argv[1]);
    } else {
        max = 100;
    }
    play();
}
