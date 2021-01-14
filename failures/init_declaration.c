int i;
int j = i; //!compile-time//

int main(int argc, char** argv) {
    int i = k; //!undeclared//
    int l = m, //!undeclared//
        m = 1;
}
