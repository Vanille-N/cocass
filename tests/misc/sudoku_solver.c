#define LEN 9

int main(int argc, char** argv) {
    int nb_solve = (argc >= 2) ? atol(argv[1]) : 1;
    for (int n = 0; n < nb_solve; n++) {
        printf("Solving sudoku n# %d\n", n);
        int nb_filled = 0;
        int** root_sudoku = allocate_sudoku();
        for (int i = 0; i < LEN; i++) {
            for (int j = 0; j < LEN; j++) {
                int next;
                scanf("%d", &next);
                root_sudoku[i][j] = next;
                if (next != 0) nb_filled++;
            }
        }
        printf("Done reading sudoku...\n");
        // display grid
        for (int i = 0; i < LEN; i++) {
            for (int j = 0; j < LEN; j++) {
                printf("%d ", root_sudoku[i][j]);
            }
            printf("\n") ;
        }
        // solve and check
        int info = routine(root_sudoku, 81 - nb_filled);
        if (info) {
            printf("Solved !\n");
        } else {
            printf("Error : failed to solve\n");
        }
        // print final result
        for (int i = 0; i < LEN; i++) {
            for (int j = 0; j < 9; j++) {
                printf("%d ", root_sudoku[i][j]) ;
            }
            printf("\n") ;
        }
        free_sudoku(root_sudoku);
    }
    return 0 ;
}

int** allocate_sudoku() {
    int** grid = malloc(LEN*QSIZE);
    for (int i = 0; i < LEN; i++) {
        grid[i] = malloc(LEN*QSIZE);
    }
    return grid;
}

void free_sudoku(int** grid) {
    for (int i = 0; i < LEN; i++) {
        free(grid[i]);
    }
    free(grid);
}

int full_check(int line, int col, int** sudoku) {
    // check that no mistakes were introduced
    int digit = sudoku[line][col];
    for (int other = 0; other < 9; other++) {
        if (sudoku[other][col] == digit && other != line) {
            return 0;
        }
        if (sudoku[line][other] == digit && other != col) {
            return 0;
        }
    }
    for (int other_line = (line / 3) * 3; other_line < (line / 3 + 1) * 3; other_line++) {
        for (int other_col = (col / 3) * 3; other_col < (col / 3 + 1) * 3; other_col++) {
            if (sudoku[other_line][other_col] == digit && (other_line != line || other_col != col)) {
                return 0;
            }
        }
    }
    return 1;
}

int routine(int** sudoku, int nb_unknown) {
    // make guesses recursively until something works
    if (nb_unknown == 0) return 1;
    int found = 0;
    int i = 0, j = 0;
    // find first blank
    while (!found) {
        if (sudoku[i][j] == 0) {
            found = 1;
        } else if (j < 8) {
            j++;
        } else {
            j = 0;
            i++;
        }
    }
    // guess next number
    for (int digit = 1; digit < 10; digit++) {
        sudoku[i][j] = digit;
        if (full_check(i, j, sudoku)) {
            int info = routine(sudoku, nb_unknown - 1);
            if (info) return 1;
        }
    }
    sudoku[i][j] = 0;
    return 0;
}
