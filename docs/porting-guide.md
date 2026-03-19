# Porting musl libc to MerlionOS

## How It Works

musl libc has a clean architecture: all 800+ C standard library functions
ultimately call `__syscall()` to talk to the kernel. The syscall layer is
the ONLY platform-specific code.

```
printf("hello %d", 42)
  → vfprintf()           # musl's formatting (portable C)
    → __stdio_write()    # musl's buffered I/O (portable C)
      → writev()         # musl's POSIX wrapper (portable C)
        → __syscall()    # PLATFORM-SPECIFIC — this is what we change
          → int 0x80     # MerlionOS kernel
```

## What We Changed (3 files)

### 1. `arch/x86_64/syscall_arch.h`
Replaces Linux `syscall` instruction with MerlionOS `int 0x80`.

```c
// Linux (upstream musl):
__asm__ __volatile__ ("syscall" : "=a"(ret) : "a"(n), "D"(a1) ...);

// MerlionOS (our port):
__asm__ __volatile__ ("int $0x80" : "=a"(ret) : "a"(n), "D"(a1) ...);
```

### 2. `src/internal/syscall_merlionos.h`
Maps Linux syscall numbers to MerlionOS numbers:

```c
// Linux __NR_read = 0, MerlionOS SYS_READ = 101
#define __NR_read   101

// Linux __NR_write = 1, MerlionOS SYS_WRITE = 0
#define __NR_write    0

// Linux __NR_epoll_create = 213, MerlionOS = 230
#define __NR_epoll_create  230
```

### 3. `arch/x86_64/crt_arch.h`
C runtime startup — `_start` calls `__libc_start_main` then exits via
MerlionOS `int 0x80` instead of Linux `syscall`.

## Syscall Coverage

| Category | Linux Syscalls | MerlionOS Equivalent | Coverage |
|----------|---------------|---------------------|----------|
| File I/O | read/write/open/close/stat/lseek | SYS 0,100-104 | ✅ Full |
| Dirs | mkdir/rmdir/getcwd/chdir/getdents | SYS 105-109 | ✅ Full |
| Memory | mmap/munmap/mprotect/brk | SYS 113,120-122 | ✅ Full |
| Process | fork/exec/exit/waitpid/getpid/kill | SYS 1,3,110-115 | ✅ Full |
| Signals | rt_sigaction/rt_sigreturn | SYS 180-181 | ✅ Basic |
| Sockets | socket/connect/bind/listen/accept | SYS 130-136 | ✅ Full |
| Socket opts | setsockopt/getsockopt | SYS 244-245 | ✅ Full |
| epoll | epoll_create/ctl/wait | SYS 230-232 | ✅ Full |
| Threads | clone/futex | SYS 190,241-242 | ✅ Full |
| Time | clock_gettime/nanosleep/gettimeofday | SYS 140-142,254-255 | ✅ Full |
| eventfd | eventfd2 | SYS 260 | ✅ Full |
| timerfd | timerfd_create/settime | SYS 263-265 | ✅ Full |
| Random | getrandom | SYS 266 | ✅ Full |
| fcntl | fcntl | SYS 243 | ✅ Basic |
| pipe | pipe/pipe2 | SYS 151 | ✅ Full |
| dup | dup/dup2 | SYS 152 | ✅ Full |
| poll | poll/ppoll/select | SYS 267 | ✅ Basic |

## Known Limitations

1. **3-arg syscall limit**: MerlionOS currently passes 3 args via registers.
   Some Linux syscalls use 4-6 args (mmap, clone flags, etc.).
   Fix: extend kernel int 0x80 handler to read rcx, r8, r9.

2. **sendmsg/recvmsg**: Simplified to sendto/recvfrom. Scatter-gather I/O
   and ancillary data (SCM_RIGHTS) not yet supported.

3. **signals**: Basic sigaction/sigreturn. No SA_SIGINFO, no signal stack.

4. **mmap**: Anonymous only. No file-backed mmap (MAP_SHARED of files).

5. **Thread creation**: SYS_CLONE creates kernel task, doesn't set child
   thread's stack/TLS. Full pthread_create needs stack setup in userspace.

## Building Envoy with musl-merlionos

```sh
# 1. Build musl
cd musl-merlionos && ./build.sh

# 2. Build libc++ against musl
# (needed for Envoy's C++ code)

# 3. Cross-compile Envoy
CC=x86_64-merlionos-gcc \
CXX=x86_64-merlionos-g++ \
bazel build \
  --config=merlionos \
  --define=wasm=disabled \
  --linkopt=-static \
  //source/exe:envoy-static

# 4. Copy to MerlionOS
cp bazel-bin/source/exe/envoy-static /path/to/merlionos-vfs/bin/envoy

# 5. Run on MerlionOS
merlion> run-user envoy
```

## Next Steps

1. **Extend syscall ABI**: Support 6 args (rcx, r8, r9) for full mmap/clone.
2. **pthread_create**: Proper userspace stack + TLS setup in clone wrapper.
3. **File-backed mmap**: MAP_SHARED for shared libraries.
4. **Signal stack**: SA_SIGINFO and alternate signal stack.
5. **Build libc++**: C++ standard library on top of musl.
6. **CI**: Automated musl build + test on MerlionOS QEMU.
