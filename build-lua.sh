#!/bin/bash
#
# Build Lua for MerlionOS.
#
# Lua is tiny (~30KB binary) and pure C. Easiest build possible.
#
# Prerequisites: run ./build.sh first (musl sysroot)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSROOT="$SCRIPT_DIR/sysroot"
LUA_DIR="$SCRIPT_DIR/lua-upstream"
LUA_VERSION="${1:-5.4.7}"

echo "=== Building Lua $LUA_VERSION for MerlionOS ==="

if [ ! -f "$SYSROOT/lib/libc.a" ]; then
    echo "ERROR: musl not built. Run ./build.sh first."
    exit 1
fi

# Step 1: Download
if [ ! -d "$LUA_DIR" ]; then
    echo "[1/3] Downloading Lua $LUA_VERSION..."
    curl -sL "https://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz" | tar xz
    mv "lua-$LUA_VERSION" "$LUA_DIR"
else
    echo "[1/3] Lua source already present"
fi

# Step 2: Build
echo "[2/3] Building..."
cd "$LUA_DIR"

CC="${CC:-gcc}"
if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
    CC="x86_64-linux-musl-gcc"
    command -v $CC &>/dev/null || CC="musl-gcc"
    command -v $CC &>/dev/null || CC="x86_64-linux-gnu-gcc"
fi

make clean 2>/dev/null || true
make -j$(nproc 2>/dev/null || echo 4) \
    CC="$CC" \
    MYCFLAGS="-static -O2 --sysroot=$SYSROOT -I$SYSROOT/include -DLUA_USE_POSIX" \
    MYLDFLAGS="-static -L$SYSROOT/lib" \
    MYLIBS="-lm" \
    posix 2>&1 | tail -5

# Step 3: Copy
echo "[3/3] Packaging..."
cp src/lua "$SCRIPT_DIR/lua-merlionos"
cp src/luac "$SCRIPT_DIR/luac-merlionos"
strip "$SCRIPT_DIR/lua-merlionos" "$SCRIPT_DIR/luac-merlionos" 2>/dev/null || true

echo ""
echo "=== Lua built for MerlionOS ==="
ls -lh "$SCRIPT_DIR/lua-merlionos" "$SCRIPT_DIR/luac-merlionos"
echo ""
echo "Run on MerlionOS:"
echo "  merlion> run-user lua"
echo '  > print("Hello from Lua on MerlionOS!")'
