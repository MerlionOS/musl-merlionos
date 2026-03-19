# Running nginx on MerlionOS

> nginx is the easiest real-world server to port — pure C, only needs musl.

## Quick Start

```sh
# 1. Build musl (~5 min)
./build.sh

# 2. Build nginx (~2 min)
./build-nginx.sh

# 3. Run on MerlionOS
merlion> run-user nginx
```

That's it. No libc++, no Bazel, no complex toolchain.

## Why nginx Is Easy

| Aspect | Envoy | nginx |
|--------|-------|-------|
| Language | C++ (1.5M lines) | C (150K lines) |
| Needs libc++ | Yes | No |
| Build system | Bazel (~2 hours) | configure+make (~2 min) |
| Dependencies | BoringSSL, protobuf, etc. | None (optional PCRE, zlib) |
| Static linking | Complex | `--with-ld-opt="-static"` |

## Architecture

```
nginx (pure C, statically linked)
    │
    ├── epoll event loop          → MerlionOS SYS_EPOLL_* (230-232)
    ├── accept() connections      → MerlionOS SYS_ACCEPT (136)
    ├── read()/write() data       → MerlionOS SYS_READ/WRITE (0, 101)
    ├── fcntl(O_NONBLOCK)         → MerlionOS SYS_FCNTL (243)
    ├── socket options            → MerlionOS SYS_SETSOCKOPT (244)
    ├── worker processes (fork)   → MerlionOS SYS_FORK (110)
    └── signals (SIGHUP reload)   → MerlionOS SYS_SIGACTION (180)
    │
    ▼
musl libc (3 files changed from upstream)
    │
    ▼
int 0x80 → MerlionOS kernel
```

## Step-by-Step

### 1. Build musl

```sh
git clone https://github.com/MerlionOS/musl-merlionos.git
cd musl-merlionos
./build.sh
```

### 2. Build nginx

```sh
./build-nginx.sh
# or specify version:
./build-nginx.sh 1.27.3
```

The script:
1. Downloads nginx source from nginx.org
2. Configures with `--with-cc-opt="-static --sysroot=sysroot"`
3. Disables optional modules (PCRE, zlib) for simpler build
4. Produces a single static `nginx-merlionos` binary

### 3. Create nginx config

```nginx
# nginx.conf for MerlionOS
worker_processes 1;
daemon off;

events {
    worker_connections 64;
    use epoll;
}

http {
    server {
        listen 80;
        server_name localhost;

        location / {
            return 200 "Hello from nginx on MerlionOS!\n";
        }

        location /proxy {
            proxy_pass http://10.0.2.2:8080;
        }

        location /status {
            stub_status on;
        }
    }
}
```

### 4. Boot MerlionOS with networking

```sh
cd merlion-kernel
qemu-system-x86_64 \
    -drive format=raw,file=target/x86_64-unknown-none/debug/bootimage-merlion-kernel.bin \
    -netdev user,id=n0,hostfwd=tcp::8080-:80 \
    -device virtio-net-pci,netdev=n0 \
    -serial stdio -m 256M
```

### 5. Run nginx

```sh
# In MerlionOS shell:
merlion> run-user nginx
[nginx] nginx/1.27.3
[nginx] listening on 0.0.0.0:80
```

### 6. Test

```sh
# From host:
curl http://localhost:8080/
# → Hello from nginx on MerlionOS!

curl http://localhost:8080/status
# → Active connections: 1
#   server accepts handled requests
#    1 1 1
```

## Syscall Coverage

| nginx Uses | musl Function | MerlionOS Syscall | Status |
|-----------|---------------|-------------------|--------|
| Event loop | `epoll_create/ctl/wait` | SYS 230-232 | ✅ |
| Listening | `socket/bind/listen` | SYS 130, 134-135 | ✅ |
| Connections | `accept/accept4` | SYS 136 | ✅ |
| Data I/O | `read/write/writev` | SYS 0, 101, 195 | ✅ |
| Non-blocking | `fcntl(O_NONBLOCK)` | SYS 243 | ✅ |
| Socket opts | `setsockopt(SO_REUSEADDR)` | SYS 244 | ✅ |
| Workers | `fork` | SYS 110 | ✅ |
| Signals | `sigaction(SIGHUP)` | SYS 180 | ✅ |
| Time | `gettimeofday` | SYS 254 | ✅ |
| Files | `open/read/close/stat` | SYS 100-103 | ✅ |
| Memory | `mmap/brk` | SYS 113, 120 | ✅ |
| Process | `getpid/exit` | SYS 1, 3 | ✅ |
| Pipe | `pipe` | SYS 151 | ✅ |
| Dup | `dup2` | SYS 152 | ✅ |

**All green.** nginx uses a subset of what Envoy needs — and we have everything.

## nginx vs MerlionOS Built-in HTTP Server

MerlionOS has a built-in HTTP server (`httpd.rs`). When to use which:

| Feature | Built-in httpd | nginx |
|---------|---------------|-------|
| Setup | Zero config | Needs nginx.conf |
| Performance | Good | Production-grade |
| Reverse proxy | Basic (http_proxy.rs) | Full featured |
| SSL/TLS | AES-128 (tls.rs) | OpenSSL/BoringSSL |
| Config reload | Restart | SIGHUP (hot reload) |
| Worker model | Single thread | Multi-process |
| Use case | Quick testing | Production deployment |

## Known Limitations

1. **sendfile()**: nginx uses sendfile for static files. Not implemented in
   MerlionOS — falls back to read()+write() which works but is slower.

2. **daemon mode**: Use `daemon off;` in config — MerlionOS doesn't have
   full daemon infrastructure yet.

3. **Log files**: Use `error_log stderr;` — write to serial console.
   File-based logging works if the VFS path exists.

4. **SSL**: nginx links OpenSSL/BoringSSL. For now, build without SSL
   (`--without-http_ssl_module`). Or use MerlionOS's built-in TLS.

## CI: Automated Build

The `build-envoy.yml` workflow also builds nginx automatically.
Go to Actions → "Build Envoy for MerlionOS" → download artifacts.

Or trigger a standalone build:

```sh
# On any Linux machine:
git clone https://github.com/MerlionOS/musl-merlionos.git
cd musl-merlionos
./build.sh && ./build-nginx.sh
# Binary: nginx-merlionos
```

## Related

- [Running Envoy on MerlionOS](running-envoy-on-merlionos.md)
- [Running MerlionClaw on MerlionOS](https://github.com/MerlionOS/libmerlion/blob/main/docs/running-merlionclaw-on-merlionos.md)
- [musl Porting Guide](porting-guide.md)
