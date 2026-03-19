# Running Envoy on MerlionOS

> From zero to Envoy proxy running on a custom OS — the complete guide.

## Overview

```
Envoy (C++, 1.5M lines)
    │
    ├── bazel build --linkopt=-static
    │
    ▼
libc++ (C++ standard library)
    │
    ├── built against musl (build-libcxx.sh)
    │
    ▼
musl libc (C standard library)
    │
    ├── 3 files patched for MerlionOS (syscall_arch.h + syscall_merlionos.h + crt_arch.h)
    │
    ▼
__syscall() → int 0x80
    │
    ▼
MerlionOS kernel (170K lines Rust, 115+ syscalls)
    │
    └── Boots on QEMU / VMware / real hardware
```

## Prerequisites

- Linux x86_64 machine (for building)
- ~100GB disk space (Envoy + LLVM + Bazel)
- ~4 hours total build time (one-time)
- QEMU (for testing)

## Step 1: Build musl libc (~5 minutes)

```sh
git clone https://github.com/MerlionOS/musl-merlionos.git
cd musl-merlionos
./build.sh
```

This produces:
```
sysroot/
├── include/    # C headers (stdio.h, stdlib.h, pthread.h, sys/epoll.h, ...)
└── lib/
    └── libc.a  # static C library (~800 functions)
```

### What build.sh does

1. Clones upstream musl from `git.musl-libc.org`
2. Replaces `arch/x86_64/syscall_arch.h` — `int 0x80` instead of `syscall`
3. Adds `src/internal/syscall_merlionos.h` — Linux→MerlionOS syscall number mapping
4. Replaces `arch/x86_64/crt_arch.h` — `_start` exits via `int 0x80`
5. Runs `./configure && make && make install`

**Only 3 files changed from upstream musl.** Everything else (800+ functions) works unchanged.

## Step 2: Build libc++ (~20 minutes)

```sh
cd musl-merlionos
./build-libcxx.sh
```

This produces:
```
sysroot/
├── include/c++/v1/    # C++ headers (string, vector, map, thread, ...)
└── lib/
    ├── libc.a         # C library (from step 1)
    ├── libc++.a       # C++ standard library
    └── libc++abi.a    # C++ ABI (exceptions, RTTI, dynamic_cast)
```

### What build-libcxx.sh does

1. Clones `llvm/llvm-project` (for libc++ source)
2. Configures with `-DLIBCXX_HAS_MUSL_LIBC=ON`
3. Builds static `libc++.a` and `libc++abi.a`
4. Installs to sysroot alongside musl headers

## Step 3: Set up Envoy build toolchain

```sh
# Install Bazel (Envoy's build system)
# See: https://bazel.build/install

# Clone Envoy
git clone https://github.com/envoyproxy/envoy.git
cd envoy
```

Create a custom toolchain config for MerlionOS:

```sh
cat > merlionos_toolchain.bzl << 'EOF'
# Bazel toolchain config for MerlionOS (static musl)
MERLIONOS_SYSROOT = "/path/to/musl-merlionos/sysroot"

MERLIONOS_COPTS = [
    "-static",
    "--sysroot=" + MERLIONOS_SYSROOT,
    "-nostdinc",
    "-I" + MERLIONOS_SYSROOT + "/include",
    "-I" + MERLIONOS_SYSROOT + "/include/c++/v1",
    "-fno-exceptions",
    "-fno-rtti",
    "-D__MERLIONOS__",
]

MERLIONOS_LINKOPTS = [
    "-static",
    "-nostdlib",
    "-L" + MERLIONOS_SYSROOT + "/lib",
    "-lc++",
    "-lc++abi",
    "-lc",
]
EOF
```

## Step 4: Build Envoy (~2-4 hours)

```sh
cd envoy

# Build static Envoy binary for MerlionOS
bazel build \
    --config=libc++ \
    --define=wasm=disabled \
    --define=tcmalloc=disabled \
    --define=admin_html=disabled \
    --copt=-static \
    --copt=--sysroot=/path/to/musl-merlionos/sysroot \
    --copt=-fno-exceptions \
    --linkopt=-static \
    --linkopt=-L/path/to/musl-merlionos/sysroot/lib \
    --linkopt=-lc++ \
    --linkopt=-lc++abi \
    --linkopt=-lc \
    //source/exe:envoy-static

# The binary is at:
# bazel-bin/source/exe/envoy-static
```

### Simplified build (Envoy core only)

If the full build is too complex, build just the core components:

```sh
bazel build \
    --define=wasm=disabled \
    --define=tcmalloc=disabled \
    --linkopt=-static \
    //source/common/http:conn_manager_lib \
    //source/common/router:router_lib \
    //source/common/upstream:cluster_manager_lib
```

## Step 5: Run Envoy on MerlionOS

### 5a. Create Envoy config

```sh
# Write config to MerlionOS VFS
cat > envoy.yaml << 'EOF'
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: backend
              domains: ["*"]
              routes:
              - match: { prefix: "/" }
                route: { cluster: service_backend }
          http_filters:
          - name: envoy.filters.http.router
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
  clusters:
  - name: service_backend
    connect_timeout: 5s
    type: STATIC
    load_assignment:
      cluster_name: service_backend
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 10.0.2.2
                port_value: 8080
EOF
```

### 5b. Boot MerlionOS with networking

```sh
cd merlion-kernel

# QEMU with network + port forwarding
qemu-system-x86_64 \
    -drive format=raw,file=target/x86_64-unknown-none/debug/bootimage-merlion-kernel.bin \
    -netdev user,id=n0,hostfwd=tcp::10000-:10000 \
    -device virtio-net-pci,netdev=n0 \
    -serial stdio \
    -m 256M
```

### 5c. Run Envoy

```sh
# In MerlionOS shell:
merlion> run-user envoy
[envoy] Envoy starting...
[envoy] Listening on 0.0.0.0:10000
[envoy] Cluster service_backend: 10.0.2.2:8080
```

### 5d. Test

```sh
# From host machine:
curl http://localhost:10000/
# → proxied to 10.0.2.2:8080 via Envoy on MerlionOS
```

## Alternative: MerlionProxy (works today)

While the full Envoy build pipeline requires a Linux build machine,
MerlionOS includes **MerlionProxy** — an Envoy-equivalent L7 proxy
built into the kernel. No compilation needed:

```sh
# In MerlionOS shell (works right now):
merlion> proxy cluster backend 10.0.2.2:8080
merlion> proxy route / backend
merlion> proxy start
MerlionProxy started

merlion> proxy test /api/users
HTTP 200 — forwarded GET /api/users → 10.0.2.2:8080
```

MerlionProxy features matching Envoy:
- L7 HTTP/gRPC routing
- Round-robin / weighted / least-connections load balancing
- Circuit breaker (closed → open → half-open)
- Health checking (configurable interval/timeout/thresholds)
- Retry policies (502/503/504 + backoff)
- Rate limiting
- mTLS (AES-128-CTR + DH key exchange)
- Access logging

## Syscall Coverage for Envoy

| Envoy Uses | musl Function | MerlionOS Syscall | Status |
|-----------|---------------|-------------------|--------|
| Event loop | `epoll_create/ctl/wait` | SYS 230-232 | ✅ |
| Sockets | `socket/bind/listen/accept/connect` | SYS 130-136 | ✅ |
| I/O | `read/write/writev/sendmsg/recvmsg` | SYS 0, 101, 195 | ✅ |
| Non-blocking | `fcntl(O_NONBLOCK)` | SYS 243 | ✅ |
| Socket opts | `setsockopt(TCP_NODELAY, SO_REUSEADDR)` | SYS 244 | ✅ |
| Threads | `pthread_create/join/mutex/condvar` | SYS 190, 241-242 | ✅ |
| Time | `clock_gettime(MONOTONIC)` | SYS 255 | ✅ |
| Timer | `timerfd_create/settime` | SYS 263-264 | ✅ |
| Wakeup | `eventfd` | SYS 260-262 | ✅ |
| Random | `getrandom` | SYS 266 | ✅ |
| Memory | `mmap/munmap/brk` | SYS 113, 120-121 | ✅ |
| Files | `open/read/write/close/stat` | SYS 100-103 | ✅ |
| Signals | `sigaction` | SYS 180 | ✅ |
| Process | `fork/exec/exit` | SYS 1, 110-111 | ✅ |

## Architecture Comparison

```
┌─────────────────────────────────────────────────────────────┐
│                    Envoy on Linux                           │
│                                                             │
│  Envoy binary (C++)                                         │
│    → glibc (2000+ functions)                                │
│      → Linux kernel (syscall instruction, ~450 syscalls)    │
│        → NIC driver → hardware                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Envoy on MerlionOS                       │
│                                                             │
│  Envoy binary (same C++ code, statically linked)            │
│    → musl-merlionos (800+ functions, 3 files changed)       │
│      → MerlionOS kernel (int 0x80, 115+ syscalls)           │
│        → e1000e NIC driver → hardware                       │
└─────────────────────────────────────────────────────────────┘
```

## Known Limitations

1. **File-backed mmap**: Envoy uses mmap for config files. MerlionOS supports
   anonymous mmap; file-backed mmap reads the whole file into memory.

2. **Signal handling**: Basic sigaction works. SA_SIGINFO and alternate
   signal stacks not yet implemented.

3. **Hot restart**: Envoy's hot restart uses Unix domain sockets and
   SCM_RIGHTS. Not yet supported on MerlionOS.

4. **Admin interface**: Envoy's admin HTML panel needs filesystem access
   for static files. Use `--define=admin_html=disabled` for now.

5. **WASM filters**: Disabled (`--define=wasm=disabled`). Would need
   a WASM runtime ported to MerlionOS.

## Troubleshooting

### "undefined reference to __syscall6"
→ musl syscall_arch.h not patched. Re-run `./build.sh`.

### "epoll_create: function not found"
→ musl headers missing epoll. Check `sysroot/include/sys/epoll.h` exists.

### Envoy crashes on startup
→ Check serial output for page fault address. Common cause: stack too small.
   Increase STACK_PAGES in `userspace.rs` from 4 to 16 (64KB stack).

### "connection refused" on port 10000
→ QEMU needs `-netdev user,hostfwd=tcp::10000-:10000`.

### Build takes too long
→ Use `--jobs=N` with Bazel. On 8-core: `bazel build --jobs=8`.
   Or build Envoy core only (without extensions).

## Related Repositories

| Repo | What | URL |
|------|------|-----|
| merlion-kernel | OS kernel (170K lines, 115 syscalls) | https://github.com/MerlionOS/merlion-kernel |
| libmerlion | Rust std library (2,198 lines) | https://github.com/MerlionOS/libmerlion |
| musl-merlionos | C/C++ standard library (musl port) | https://github.com/MerlionOS/musl-merlionos |
