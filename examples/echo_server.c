/*
 * TCP Echo Server — demonstrates networking on MerlionOS.
 *
 * Compile:
 *   x86_64-linux-musl-gcc -static -o echo_server echo_server.c
 *
 * Run on MerlionOS:
 *   run-user echo_server
 */
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

int main() {
    int server_fd, client_fd;
    struct sockaddr_in addr;
    char buf[256];

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        printf("socket() failed\n");
        return 1;
    }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(8080);

    if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        printf("bind() failed\n");
        return 1;
    }

    listen(server_fd, 5);
    printf("Echo server listening on :8080\n");

    while (1) {
        client_fd = accept(server_fd, NULL, NULL);
        if (client_fd < 0) continue;

        printf("Client connected\n");
        int n = read(client_fd, buf, sizeof(buf) - 1);
        if (n > 0) {
            buf[n] = '\0';
            printf("Received: %s\n", buf);
            write(client_fd, buf, n);  /* echo back */
        }
        close(client_fd);
    }

    return 0;
}
