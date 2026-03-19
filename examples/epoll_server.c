/*
 * Epoll-based HTTP Server — demonstrates event-driven I/O on MerlionOS.
 *
 * This is the same pattern Envoy/nginx use internally.
 *
 * Compile:
 *   x86_64-linux-musl-gcc -static -o epoll_server epoll_server.c
 *
 * Run on MerlionOS:
 *   run-user epoll_server
 */
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/epoll.h>
#include <netinet/in.h>
#include <unistd.h>
#include <fcntl.h>

#define MAX_EVENTS 16
#define PORT 8080

static const char RESPONSE[] =
    "HTTP/1.1 200 OK\r\n"
    "Content-Type: text/plain\r\n"
    "Content-Length: 26\r\n"
    "Connection: close\r\n"
    "\r\n"
    "Hello from MerlionOS!\r\n\r\n";

int set_nonblocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

int main() {
    int server_fd, epfd;
    struct sockaddr_in addr;
    struct epoll_event ev, events[MAX_EVENTS];

    /* Create server socket */
    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) { printf("socket failed\n"); return 1; }

    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        printf("bind failed\n"); return 1;
    }
    listen(server_fd, 128);
    set_nonblocking(server_fd);

    /* Create epoll instance */
    epfd = epoll_create1(0);
    if (epfd < 0) { printf("epoll_create failed\n"); return 1; }

    ev.events = EPOLLIN;
    ev.data.fd = server_fd;
    epoll_ctl(epfd, EPOLL_CTL_ADD, server_fd, &ev);

    printf("Epoll HTTP server on :%d (event-driven, Envoy-style)\n", PORT);

    /* Event loop */
    while (1) {
        int n = epoll_wait(epfd, events, MAX_EVENTS, -1);
        for (int i = 0; i < n; i++) {
            if (events[i].data.fd == server_fd) {
                /* Accept new connection */
                int client = accept(server_fd, NULL, NULL);
                if (client >= 0) {
                    set_nonblocking(client);
                    ev.events = EPOLLIN | EPOLLET;
                    ev.data.fd = client;
                    epoll_ctl(epfd, EPOLL_CTL_ADD, client, &ev);
                }
            } else {
                /* Handle client data */
                char buf[512];
                int fd = events[i].data.fd;
                int nr = read(fd, buf, sizeof(buf));
                if (nr > 0) {
                    write(fd, RESPONSE, sizeof(RESPONSE) - 1);
                }
                epoll_ctl(epfd, EPOLL_CTL_DEL, fd, NULL);
                close(fd);
            }
        }
    }

    return 0;
}
