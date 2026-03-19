/*
 * File I/O — demonstrates filesystem operations on MerlionOS.
 *
 * Compile:
 *   x86_64-linux-musl-gcc -static -o file_io file_io.c
 *
 * Run on MerlionOS:
 *   run-user file_io
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>

int main() {
    FILE *fp;
    char buf[256];

    /* Write a file */
    printf("Writing /tmp/test.txt...\n");
    fp = fopen("/tmp/test.txt", "w");
    if (!fp) { printf("fopen(w) failed\n"); return 1; }
    fprintf(fp, "MerlionOS file I/O works!\n");
    fprintf(fp, "Written by a C program using musl libc.\n");
    fclose(fp);

    /* Read it back */
    printf("Reading /tmp/test.txt...\n");
    fp = fopen("/tmp/test.txt", "r");
    if (!fp) { printf("fopen(r) failed\n"); return 1; }
    while (fgets(buf, sizeof(buf), fp)) {
        printf("  %s", buf);
    }
    fclose(fp);

    /* Read /proc/version */
    printf("\nKernel version:\n");
    fp = fopen("/proc/version", "r");
    if (fp) {
        fgets(buf, sizeof(buf), fp);
        printf("  %s\n", buf);
        fclose(fp);
    }

    /* Memory allocation */
    printf("malloc test: ");
    char *ptr = malloc(128);
    if (ptr) {
        strcpy(ptr, "heap works!");
        printf("%s\n", ptr);
        free(ptr);
    }

    printf("All tests passed!\n");
    return 0;
}
