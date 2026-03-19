#!/bin/bash
#
# Build Node.js for MerlionOS.
#
# Node.js = V8 (C++) + libuv (C) + node bindings.
# Needs musl + libc++. Larger build than Lua but unlocks npm ecosystem.
#
# Prerequisites:
#   ./build.sh         (musl sysroot)
#   ./build-libcxx.sh  (libc++ for V8)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSROOT="$SCRIPT_DIR/sysroot"
NODE_DIR="$SCRIPT_DIR/node-upstream"
NODE_VERSION="${1:-v22.13.1}"

echo "=== Building Node.js $NODE_VERSION for MerlionOS ==="

if [ ! -f "$SYSROOT/lib/libc.a" ]; then
    echo "ERROR: musl not built. Run ./build.sh first."
    exit 1
fi

# Step 1: Download
if [ ! -d "$NODE_DIR" ]; then
    echo "[1/4] Downloading Node.js $NODE_VERSION..."
    curl -sL "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION.tar.xz" | tar xJ
    mv "node-$NODE_VERSION" "$NODE_DIR"
else
    echo "[1/4] Node.js source already present"
fi

# Step 2: Configure
echo "[2/4] Configuring..."
cd "$NODE_DIR"

CC="${CC:-gcc}"
CXX="${CXX:-g++}"
if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
    CC="x86_64-linux-musl-gcc"
    CXX="x86_64-linux-musl-g++"
    if ! command -v $CC &>/dev/null; then
        CC="x86_64-linux-gnu-gcc"
        CXX="x86_64-linux-gnu-g++"
    fi
fi

# Node's configure accepts these flags for static musl build
./configure \
    --dest-cpu=x64 \
    --dest-os=linux \
    --fully-static \
    --without-npm \
    --without-inspector \
    --without-intl \
    --without-dtrace \
    --without-etw \
    --without-ssl \
    --openssl-no-asm \
    --with-intl=none \
    CC="$CC" \
    CXX="$CXX" \
    CFLAGS="--sysroot=$SYSROOT -I$SYSROOT/include" \
    CXXFLAGS="--sysroot=$SYSROOT -I$SYSROOT/include -I$SYSROOT/include/c++/v1 -nostdinc++" \
    LDFLAGS="-static -L$SYSROOT/lib -lc++ -lc++abi -lc" \
    2>&1 | tail -10

# Step 3: Build
echo "[3/4] Building Node.js (this takes 30-60 minutes)..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) \
    2>&1 | tail -10

# Step 4: Copy
echo "[4/4] Packaging..."
if [ -f out/Release/node ]; then
    cp out/Release/node "$SCRIPT_DIR/node-merlionos"
    strip "$SCRIPT_DIR/node-merlionos" 2>/dev/null || true
    echo ""
    echo "=== Node.js built for MerlionOS ==="
    file "$SCRIPT_DIR/node-merlionos"
    ls -lh "$SCRIPT_DIR/node-merlionos"
    echo ""
    echo "Run on MerlionOS:"
    echo "  merlion> run-user node"
    echo '  > console.log("Hello from Node.js on MerlionOS!")'
else
    echo ""
    echo "Build did not produce binary."
    echo "Check build logs — V8 compilation may need additional patches."
fi
