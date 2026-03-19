/*
 * Hello World — first C program on MerlionOS.
 *
 * Compile:
 *   x86_64-linux-musl-gcc -static -o hello hello.c
 *
 * Run on MerlionOS:
 *   run-user hello
 */
#include <stdio.h>

int main() {
    printf("Hello from C on MerlionOS!\n");
    printf("This program uses musl libc → MerlionOS syscalls.\n");
    return 0;
}
