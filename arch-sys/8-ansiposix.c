int main() {
	while (1) {
		printf("hello ");	// buffered output
		write(1,"world ",6);		// unbuffered output
	}
}
