int i;

int main() {
    int j;
    {
        int i;
        {
            int i = 1;
        }
        {
            int k = 5;
            i = k;
        }
        j = i;
    }
    i = j;
    return i;
}
