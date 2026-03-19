# musl-merlionos

musl libc port for MerlionOS — enables standard C/C++ programs to run on MerlionOS.

## Architecture

```
C/C++ program (Envoy, nginx, etc.)
    │
    ▼
musl libc (standard C library)
    │  printf, malloc, pthread_create, socket, epoll...
    ▼
__syscall() — musl internal syscall interface
    │
    ▼
MerlionOS syscall mapping (this port)
    │  Linux syscall numbers → MerlionOS syscall numbers
    ▼
int 0x80 → MerlionOS kernel (115+ syscalls)
```

## How musl Works

musl uses a single `__syscall()` function for ALL kernel interaction.
On Linux, this does `syscall` instruction with Linux syscall numbers.
For MerlionOS, we replace this with `int 0x80` + our syscall numbers.

## Building

```sh
# Clone upstream musl
git clone https://git.musl-libc.org/git/musl
cd musl

# Apply MerlionOS patches
cp -r /path/to/musl-merlionos/arch/x86_64/* arch/x86_64/
cp /path/to/musl-merlionos/src/internal/syscall_merlionos.h src/internal/

# Configure for MerlionOS
./configure --target=x86_64-merlionos --prefix=/opt/merlionos-sysroot
make -j$(nproc)
make install

# Cross-compile C programs
x86_64-merlionos-gcc -static hello.c -o hello
# Copy to MerlionOS VFS → run-user hello
```

## Syscall Mapping

musl uses Linux syscall numbers internally. This port maps them
to MerlionOS numbers at the lowest level (__syscall).

See `src/internal/syscall_merlionos.h` for the complete mapping.
