#!/bin/bash
#
# Build nginx for MerlionOS.
#
# nginx is pure C — only needs musl libc (no libc++ required).
# Much simpler than Envoy.
#
# Prerequisites: run ./build.sh first (musl sysroot)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSROOT="$SCRIPT_DIR/sysroot"
NGINX_DIR="$SCRIPT_DIR/nginx-upstream"
NGINX_VERSION="${1:-1.27.3}"

echo "=== Building nginx $NGINX_VERSION for MerlionOS ==="

# Check musl
if [ ! -f "$SYSROOT/lib/libc.a" ]; then
    echo "ERROR: musl not built. Run ./build.sh first."
    exit 1
fi

# Step 1: Download nginx
if [ ! -d "$NGINX_DIR" ]; then
    echo "[1/4] Downloading nginx $NGINX_VERSION..."
    curl -sL "https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" | tar xz
    mv "nginx-$NGINX_VERSION" "$NGINX_DIR"
else
    echo "[1/4] nginx source already present"
fi

# Step 2: Configure
echo "[2/4] Configuring..."
cd "$NGINX_DIR"

CC="${CC:-gcc}"
if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
    CC="x86_64-linux-musl-gcc"
    if ! command -v $CC &>/dev/null; then
        CC="x86_64-linux-gnu-gcc"
    fi
    if ! command -v $CC &>/dev/null; then
        echo "WARNING: No x86_64 cross-compiler. Patches applied, skipping build."
        exit 0
    fi
fi

./configure \
    --prefix=/usr/local/nginx \
    --with-cc="$CC" \
    --with-cc-opt="-static -O2 --sysroot=$SYSROOT -I$SYSROOT/include" \
    --with-ld-opt="-static -L$SYSROOT/lib" \
    --without-http_rewrite_module \
    --without-http_gzip_module \
    --without-pcre \
    --without-http_upstream_zone_module \
    --with-poll_module \
    2>&1 | tail -10

# Step 3: Build
echo "[3/4] Building..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) 2>&1 | tail -5

# Step 4: Copy binary
echo "[4/4] Packaging..."
cp objs/nginx "$SCRIPT_DIR/nginx-merlionos"
ls -lh "$SCRIPT_DIR/nginx-merlionos"

echo ""
echo "=== nginx built for MerlionOS ==="
echo "Binary: $SCRIPT_DIR/nginx-merlionos"
echo "Size:   $(du -h "$SCRIPT_DIR/nginx-merlionos" | cut -f1)"
echo ""
echo "Run on MerlionOS:"
echo "  # Copy nginx-merlionos to MerlionOS VFS"
echo "  merlion> run-user nginx"
