#!/bin/bash
#
# Build libc++ (C++ standard library) against musl-merlionos.
#
# This enables C++ programs (including Envoy) to compile for MerlionOS.
#
# Prerequisites:
#   - musl built (run ./build.sh first)
#   - LLVM/Clang installed
#   - CMake
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSROOT="$SCRIPT_DIR/sysroot"
LLVM_DIR="$SCRIPT_DIR/llvm-project"
BUILD_DIR="$SCRIPT_DIR/build-libcxx"

echo "=== Building libc++ for MerlionOS ==="

# Check musl is built
if [ ! -f "$SYSROOT/lib/libc.a" ]; then
    echo "ERROR: musl not built yet. Run ./build.sh first."
    exit 1
fi

# Step 1: Clone LLVM (for libc++ source)
if [ ! -d "$LLVM_DIR" ]; then
    echo "[1/4] Cloning LLVM (libc++ source only)..."
    git clone --depth 1 https://github.com/llvm/llvm-project.git "$LLVM_DIR"
else
    echo "[1/4] LLVM already cloned"
fi

# Step 2: Configure libc++ build
echo "[2/4] Configuring libc++..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake "$LLVM_DIR/libcxx" \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_FLAGS="--sysroot=$SYSROOT -nostdinc -I$SYSROOT/include" \
    -DCMAKE_CXX_FLAGS="--sysroot=$SYSROOT -nostdinc -nostdinc++ -I$SYSROOT/include" \
    -DCMAKE_INSTALL_PREFIX="$SYSROOT" \
    -DLIBCXX_ENABLE_SHARED=OFF \
    -DLIBCXX_ENABLE_STATIC=ON \
    -DLIBCXX_HAS_MUSL_LIBC=ON \
    -DLIBCXX_ENABLE_THREADS=ON \
    -DLIBCXX_HAS_PTHREAD_API=ON \
    -DLIBCXX_ENABLE_FILESYSTEM=ON \
    -DLIBCXX_ENABLE_RANDOM_DEVICE=OFF \
    -DLIBCXX_ENABLE_LOCALIZATION=OFF \
    -DLIBCXX_ENABLE_UNICODE=OFF \
    -DLIBCXX_ENABLE_WIDE_CHARACTERS=OFF \
    -DLIBCXX_ENABLE_EXCEPTIONS=OFF \
    -DLIBCXX_ENABLE_RTTI=ON \
    -DLIBCXX_USE_COMPILER_RT=ON \
    -DLIBCXX_CXX_ABI=libcxxabi \
    -DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    2>&1 | tail -5

# Step 3: Build
echo "[3/4] Building libc++..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) 2>&1 | tail -5

# Step 4: Install
echo "[4/4] Installing to sysroot..."
make install 2>&1 | tail -3

echo ""
echo "=== libc++ for MerlionOS built successfully ==="
echo "Sysroot: $SYSROOT"
echo ""
echo "To compile C++ programs for MerlionOS:"
echo "  clang++ -static -nostdinc++ -I$SYSROOT/include/c++/v1 \\"
echo "      -L$SYSROOT/lib -lc++ -lc++abi -lc \\"
echo "      -o myprogram myprogram.cpp"
echo ""
echo "=== Building Envoy ==="
echo "See docs/porting-guide.md for full Envoy build instructions."
