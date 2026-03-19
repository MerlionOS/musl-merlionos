#!/bin/bash
#
# Build Redis for MerlionOS.
#
# Redis is pure C, in-memory by design — perfect fit for MerlionOS.
# Simplest server build: just make with musl.
#
# Prerequisites: run ./build.sh first (musl sysroot)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSROOT="$SCRIPT_DIR/sysroot"
REDIS_DIR="$SCRIPT_DIR/redis-upstream"
REDIS_VERSION="${1:-7.4.2}"

echo "=== Building Redis $REDIS_VERSION for MerlionOS ==="

if [ ! -f "$SYSROOT/lib/libc.a" ]; then
    echo "ERROR: musl not built. Run ./build.sh first."
    exit 1
fi

# Step 1: Download
if [ ! -d "$REDIS_DIR" ]; then
    echo "[1/3] Downloading Redis $REDIS_VERSION..."
    curl -sL "https://github.com/redis/redis/archive/refs/tags/$REDIS_VERSION.tar.gz" | tar xz
    mv "redis-$REDIS_VERSION" "$REDIS_DIR"
else
    echo "[1/3] Redis source already present"
fi

# Step 2: Build
echo "[2/3] Building..."
cd "$REDIS_DIR"

CC="${CC:-gcc}"
if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
    CC="x86_64-linux-musl-gcc"
    command -v $CC &>/dev/null || CC="musl-gcc"
    command -v $CC &>/dev/null || CC="x86_64-linux-gnu-gcc"
fi

make distclean 2>/dev/null || true
make -j$(nproc 2>/dev/null || echo 4) \
    CC="$CC" \
    CFLAGS="-static -O2 --sysroot=$SYSROOT -I$SYSROOT/include" \
    LDFLAGS="-static -L$SYSROOT/lib" \
    MALLOC=libc \
    USE_JEMALLOC=no \
    USE_SYSTEMD=no \
    BUILD_TLS=no \
    redis-server redis-cli \
    2>&1 | tail -10

# Step 3: Copy
echo "[3/3] Packaging..."
cp src/redis-server "$SCRIPT_DIR/redis-server-merlionos"
cp src/redis-cli "$SCRIPT_DIR/redis-cli-merlionos"
strip "$SCRIPT_DIR/redis-server-merlionos" "$SCRIPT_DIR/redis-cli-merlionos" 2>/dev/null || true

echo ""
echo "=== Redis built for MerlionOS ==="
ls -lh "$SCRIPT_DIR/redis-server-merlionos" "$SCRIPT_DIR/redis-cli-merlionos"
echo ""
echo "Run on MerlionOS:"
echo "  merlion> run-user redis-server"
echo "  merlion> run-user redis-cli ping"
echo "  PONG"
