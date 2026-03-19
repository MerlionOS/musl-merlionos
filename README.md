# musl-merlionos

musl libc port for MerlionOS — enables standard C/C++/Rust programs to run on MerlionOS.

## Quick Start

```sh
# 1. Build musl libc
./build.sh

# 2. Build examples
cd examples && make

# 3. Copy to MerlionOS and run
# In MerlionOS shell:
run-user hello
run-user echo_server
run-user epoll_server
```

## Examples

| Example | Language | Demonstrates |
|---------|----------|-------------|
| `hello.c` | C | printf, basic I/O |
| `file_io.c` | C | fopen/fread/fwrite, malloc, /proc |
| `echo_server.c` | C | TCP sockets, accept/read/write |
| `epoll_server.c` | C | epoll event loop (Envoy/nginx pattern) |
| `threads.c` | C | pthreads, mutex, concurrent counter |
| `hello_cpp.cpp` | C++ | std::string, std::vector, std::map |
| `hello_rust.rs` | Rust | HashMap, TcpListener, threads, timing, file I/O |

## Architecture

```
C/C++/Rust program
    │
    ▼
musl libc / libc++ / libmerlion (standard libraries)
    │
    ▼
__syscall() — int 0x80 (this port's 3 changed files)
    │
    ▼
MerlionOS kernel (115+ syscalls, 6-arg ABI)
```

## What We Changed from Upstream musl

Only **3 files** — everything else (800+ C functions) works unchanged:

| File | What | Why |
|------|------|-----|
| `arch/x86_64/syscall_arch.h` | `int 0x80` instead of `syscall` | MerlionOS uses int 0x80 |
| `src/internal/syscall_merlionos.h` | Linux → MerlionOS syscall numbers | Different numbering scheme |
| `arch/x86_64/crt_arch.h` | `_start` exits via `int 0x80` | Runtime startup |

## Build Scripts

| Script | What It Builds |
|--------|---------------|
| `build.sh` | musl libc.a (C standard library) |
| `build-libcxx.sh` | libc++.a (C++ standard library) |
| `examples/Makefile` | 5 example C programs |

## Syscall ABI

```
Instruction: int 0x80
Registers:   rax = number
             rdi = arg1, rsi = arg2, rdx = arg3
             r10 = arg4, r8  = arg5, r9  = arg6
Return:      rax (negative = error)
```

All 6 arguments supported — enables mmap, clone, and all multi-arg syscalls.

## Path to Envoy

```sh
./build.sh              # Step 1: musl libc.a
./build-libcxx.sh       # Step 2: libc++.a + libc++abi.a
# Step 3: bazel build Envoy with static musl toolchain
# Step 4: run-user envoy
```

## Related Repos

| Repo | Purpose |
|------|---------|
| [merlion-kernel](https://github.com/MerlionOS/merlion-kernel) | OS kernel (170K lines, 115 syscalls) |
| [libmerlion](https://github.com/MerlionOS/libmerlion) | Rust std library (2,198 lines) |
| [musl-merlionos](https://github.com/MerlionOS/musl-merlionos) | C/C++ libc (this repo) |

## License

MIT (same as MerlionOS)
