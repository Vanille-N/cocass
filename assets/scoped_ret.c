int i;

int main() {
    int j;
    {
        int i;
        {
            int i;
            i = 1;
        }
        {
            int k;
            k = 5;
            i = k;
        }
        j = i;
    }
    i = j;
    return i;
}
