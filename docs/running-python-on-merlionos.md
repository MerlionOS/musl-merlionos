# Running Python on MerlionOS

> CPython is pure C — just needs musl. No libc++ needed.

## Quick Start

```sh
./build.sh            # musl libc (~5 min, one-time)
./build-python.sh     # CPython 3.13 (~5 min)
# Copy to MerlionOS → run-user python3
```

## Why Python Is Easy

| Aspect | Python | Envoy | nginx |
|--------|--------|-------|-------|
| Language | C | C++ | C |
| Needs libc++ | No | Yes | No |
| Build system | configure+make | Bazel | configure+make |
| Build time | ~5 min | ~3 hours | ~2 min |
| Binary size | ~5 MB | ~50 MB | ~1 MB |

## Architecture

```
Python script (hello.py)
    │
    ▼
CPython interpreter (C, statically linked)
    │
    ├── print()     → write()   → SYS_WRITE (0)
    ├── open()      → fopen()   → SYS_OPEN (100)
    ├── os.getpid() → getpid()  → SYS_GETPID (3)
    ├── time.sleep()→ nanosleep → SYS_NANOSLEEP (141)
    ├── socket()    → socket()  → SYS_SOCKET (130)
    └── threading   → pthread   → SYS_CLONE (190) + SYS_FUTEX (241)
    │
    ▼
musl libc (3 files changed) → int 0x80 → MerlionOS kernel
```

## What Works

| Python Feature | MerlionOS Support |
|---------------|-------------------|
| print/input | ✅ SYS_WRITE/READ |
| File I/O (open/read/write) | ✅ SYS_OPEN/READ/WRITE |
| os module (getpid, getcwd, chdir) | ✅ SYS_GETPID/GETCWD/CHDIR |
| time module (sleep, monotonic) | ✅ SYS_NANOSLEEP/CLOCK_MONOTONIC |
| socket module (TCP/UDP) | ✅ SYS_SOCKET/CONNECT/BIND/LISTEN |
| http.server | ✅ via socket module |
| json module | ✅ pure Python |
| threading module | ✅ SYS_CLONE + SYS_FUTEX |
| subprocess | ✅ SYS_FORK + SYS_EXEC |
| hashlib | ⚠️ needs OpenSSL or built-in |
| ctypes/libffi | ❌ disabled |
| tkinter | ❌ disabled (no GUI lib) |
| curses | ❌ disabled (no ncurses) |

## Examples

### hello.py
```python
print("Hello from Python on MerlionOS!")
import os
print(f"PID: {os.getpid()}")
```

### HTTP server
```python
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Hello from Python on MerlionOS!\n")

HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
```

## Running

### Boot MerlionOS

```sh
qemu-system-x86_64 \
    -drive format=raw,file=target/x86_64-unknown-none/debug/bootimage-merlion-kernel.bin \
    -netdev user,id=n0,hostfwd=tcp::8080-:8080 \
    -device virtio-net-pci,netdev=n0 \
    -serial stdio -m 256M
```

### Interactive Python

```sh
merlion> run-user python3
Python 3.13.2 (MerlionOS)
>>> print("Hello!")
Hello!
>>> import os; os.getpid()
42
>>> 2 ** 100
1267650600228229401496703205376
```

### Run script

```sh
merlion> run-user python3 hello.py
Hello from Python on MerlionOS!
```

### Python HTTP server

```sh
merlion> run-user python3 http_server.py
Python HTTP server on :8080

# From host:
curl http://localhost:8080/
# → Hello from Python HTTP server on MerlionOS!

curl http://localhost:8080/status
# → {"os": "MerlionOS", "python": "3.13.2", "pid": 42}
```

## Build Details

### What's disabled

To minimize dependencies, these modules are disabled:

```
_ctypes      — needs libffi
_decimal     — needs libmpdec
_dbm/_gdbm   — needs dbm/gdbm libraries
_lzma/_bz2   — needs compression libraries
_tkinter     — needs Tk/Tcl
_curses      — needs ncurses
readline     — needs libreadline
```

Core Python (math, json, collections, http, socket, threading, os, sys, io)
all work without these.

### Enabling more modules

To enable modules with dependencies, build the dependency against musl first:

```sh
# Example: enable zlib (for gzip/zipfile)
cd zlib-src && CC=musl-gcc ./configure --static && make
cp libz.a ../sysroot/lib/
# Then rebuild Python with zlib enabled
```

## Related

- [Running nginx on MerlionOS](running-nginx-on-merlionos.md) — C web server
- [Running Envoy on MerlionOS](running-envoy-on-merlionos.md) — C++ proxy
- [Running Caddy on MerlionOS](https://github.com/MerlionOS/go-merlionos/blob/main/docs/running-caddy-on-merlionos.md) — Go web server
- [Running MerlionClaw on MerlionOS](https://github.com/MerlionOS/libmerlion/blob/main/docs/running-merlionclaw-on-merlionos.md) — Rust agent
