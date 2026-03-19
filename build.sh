#!/bin/bash
#
# Build musl libc for MerlionOS.
#
# This script:
# 1. Clones upstream musl (if not present)
# 2. Patches syscall layer for MerlionOS
# 3. Builds static libc.a
# 4. Creates sysroot for cross-compilation
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MUSL_DIR="$SCRIPT_DIR/musl-upstream"
SYSROOT="$SCRIPT_DIR/sysroot"

echo "=== Building musl libc for MerlionOS ==="

# Step 1: Clone upstream musl
if [ ! -d "$MUSL_DIR" ]; then
    echo "[1/5] Cloning musl..."
    git clone --depth 1 https://git.musl-libc.org/git/musl "$MUSL_DIR"
else
    echo "[1/5] musl already cloned"
fi

# Step 2: Patch syscall layer
echo "[2/5] Patching for MerlionOS..."

# Replace x86_64 syscall entry with our int 0x80 version
cp "$SCRIPT_DIR/arch/x86_64/syscall_arch.h" "$MUSL_DIR/arch/x86_64/syscall_arch.h"
cp "$SCRIPT_DIR/arch/x86_64/crt_arch.h" "$MUSL_DIR/arch/x86_64/crt_arch.h"

# Add MerlionOS syscall number mapping
cp "$SCRIPT_DIR/src/internal/syscall_merlionos.h" "$MUSL_DIR/src/internal/"

# Patch src/internal/syscall.h to include our mapping
if ! grep -q "syscall_merlionos" "$MUSL_DIR/src/internal/syscall.h" 2>/dev/null; then
    # Add include at the top of the syscall number definitions
    sed -i.bak '/#ifndef _INTERNAL_SYSCALL_H/a\
#include "syscall_merlionos.h"
' "$MUSL_DIR/src/internal/syscall.h" 2>/dev/null || \
    sed -i '' '/#ifndef _INTERNAL_SYSCALL_H/a\
#include "syscall_merlionos.h"
' "$MUSL_DIR/src/internal/syscall.h"
fi

echo "   Patched syscall_arch.h (int 0x80 instead of syscall instruction)"
echo "   Added syscall_merlionos.h (Linux → MerlionOS number mapping)"

# Step 3: Configure
echo "[3/5] Configuring..."
cd "$MUSL_DIR"

# Use gcc for x86_64 (cross-compile if on ARM Mac)
CC="${CC:-gcc}"
if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
    CC="x86_64-linux-gnu-gcc"
    if ! command -v $CC &>/dev/null; then
        CC="x86_64-elf-gcc"
    fi
    if ! command -v $CC &>/dev/null; then
        echo "WARNING: No x86_64 cross-compiler found."
        echo "Install with: brew install x86_64-elf-gcc (macOS)"
        echo "         or: apt install gcc-x86-64-linux-gnu (Linux)"
        echo "Skipping build — patches applied successfully."
        exit 0
    fi
fi

./configure \
    --target=x86_64 \
    --prefix="$SYSROOT" \
    --disable-shared \
    CC="$CC" \
    CFLAGS="-O2 -fno-stack-protector -fno-pic -static" \
    2>&1 | tail -5

# Step 4: Build
echo "[4/5] Building..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) 2>&1 | tail -3

# Step 5: Install to sysroot
echo "[5/5] Installing to sysroot..."
make install 2>&1 | tail -3

echo ""
echo "=== musl for MerlionOS built successfully ==="
echo "Sysroot: $SYSROOT"
echo ""
echo "To compile C programs for MerlionOS:"
echo "  $CC -static -nostdlib -I$SYSROOT/include -L$SYSROOT/lib \\"
echo "      -o myprogram myprogram.c -lc"
echo ""
echo "Or use the sysroot with Rust:"
echo "  RUSTFLAGS=\"-C linker=$CC -C link-arg=-L$SYSROOT/lib -C link-arg=-lc\" \\"
echo "      cargo build --target x86_64-unknown-merlionos"
