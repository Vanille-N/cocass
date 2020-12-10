q = """int main() {
\tchar* c;
\tc = "int main() {%c%cchar* c;%c%cc = %c%s%c;%c%cprintf(c,10,9,10,9,34,c,34,10,9,10,9,10,10);%c%creturn 0;%c}%c";
\tprintf(c,10,9,10,9,34,c,34,10,9,10,9,10,10);
\treturn 0;
}
"""

def expect(*args):
    return (0, q, "")

data = [
    [],
]
