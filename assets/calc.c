int str_to_int(char* s) {
    int acc, len, i;
    acc = 0;
    len = strlen(s);
    i = ((*s&BYTE) == '-');
    for (; i < len; i++) {
        if (isdigit(*(s+i)&BYTE)) {
            acc = acc * 10 + (*(s+i)&BYTE) - '0';
        } else {
            throw InvalidInt(s);
        }
    }
    return ((*s&BYTE) == '-') ? -acc : acc;
}

int main(int argc, char** argv) {
    int m, n;
    int i;
    int result;
    if (argc == 1 || argc % 3 != 1) {
        fprintf(stderr, "Usage: calc <op> <m> <n> [<op> <m> <n> ...]\n  where <m>, <n>: integers; <op>: +, x, /, %, -");
        exit(1);
    }
    for (i = 0; 3*i+1 < argc; i++) {
        try {
            int op;
            m = str_to_int(argv[3*i+2]);
            n = str_to_int(argv[3*i+3]);
            op = *argv[3*i+1]&BYTE;
            switch (op) {
                case '+': result = m + n; break;
                case '-': result = m - n; break;
                case 'x': result = m * n; break;
                case '/':
                    if (n == 0) throw ZeroDivisionError;
                    result = m / n; break;
                case '%':
                    if (n == 0) throw ZeroDivisionError;
                    result = m % n; break;
                default:
                    throw InvalidOperation(op);
            }
            printf("%d %c %d = %d\n", m, op, n, result);
        } catch (ZeroDivisionError) {
            fprintf(stderr, "Cannot divide by zero: %d %c %d\n.", m, *argv[3*i+1], n);
        } catch (InvalidInt s) {
            fprintf(stderr, "%s is not a valid base 10 integer.\n", s);
        } catch (InvalidOperation op) {
            fprintf(stderr, "Unknown operator %c.\n", op);
        }
    }
}
