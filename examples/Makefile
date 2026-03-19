# Build C examples for MerlionOS.
#
# Usage:
#   make              # build all examples
#   make hello        # build one example
#   make clean        # remove binaries
#
# Requires: musl cross-compiler (x86_64-linux-musl-gcc)
#   macOS: brew install filosottile/musl-cross/musl-cross
#   Linux: apt install musl-tools
#
# Or use the sysroot from ./build.sh:
#   make CC="gcc --sysroot=../sysroot"

CC ?= x86_64-linux-musl-gcc
CFLAGS = -static -O2 -Wall
LDFLAGS = -static

PROGRAMS = hello echo_server epoll_server threads file_io

.PHONY: all clean

all: $(PROGRAMS)
	@echo ""
	@echo "=== All examples built ==="
	@echo "Copy to MerlionOS and run with: run-user <name>"
	@echo ""
	@ls -lh $(PROGRAMS) 2>/dev/null

hello: hello.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	@echo "Built: $@ ($$(wc -c < $@ | tr -d ' ') bytes)"

echo_server: echo_server.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	@echo "Built: $@ ($$(wc -c < $@ | tr -d ' ') bytes)"

epoll_server: epoll_server.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	@echo "Built: $@ ($$(wc -c < $@ | tr -d ' ') bytes)"

threads: threads.c
	$(CC) $(CFLAGS) $(LDFLAGS) -pthread -o $@ $<
	@echo "Built: $@ ($$(wc -c < $@ | tr -d ' ') bytes)"

file_io: file_io.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	@echo "Built: $@ ($$(wc -c < $@ | tr -d ' ') bytes)"

clean:
	rm -f $(PROGRAMS)
