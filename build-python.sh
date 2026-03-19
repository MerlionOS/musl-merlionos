#!/bin/bash
#
# Build CPython 3.13 for MerlionOS.
#
# CPython is pure C — needs musl libc (no libc++ required).
# Produces a static python3 binary.
#
# Prerequisites: run ./build.sh first (musl sysroot)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSROOT="$SCRIPT_DIR/sysroot"
PYTHON_DIR="$SCRIPT_DIR/cpython-upstream"
PYTHON_VERSION="${1:-3.13.2}"
PYTHON_MAJOR="3.13"

echo "=== Building CPython $PYTHON_VERSION for MerlionOS ==="

if [ ! -f "$SYSROOT/lib/libc.a" ]; then
    echo "ERROR: musl not built. Run ./build.sh first."
    exit 1
fi

# Step 1: Download CPython
if [ ! -d "$PYTHON_DIR" ]; then
    echo "[1/5] Downloading CPython $PYTHON_VERSION..."
    curl -sL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" | tar xJ
    mv "Python-$PYTHON_VERSION" "$PYTHON_DIR"
else
    echo "[1/5] CPython source already present"
fi

# Step 2: Build host Python first (needed for cross-compile)
echo "[2/5] Building host Python (for cross-compile bootstrap)..."
HOST_PYTHON="$SCRIPT_DIR/python-host"
if [ ! -f "$HOST_PYTHON/python" ]; then
    mkdir -p "$HOST_PYTHON"
    cd "$PYTHON_DIR"
    ./configure --prefix="$HOST_PYTHON/install" 2>&1 | tail -3
    make -j$(nproc 2>/dev/null || echo 4) python 2>&1 | tail -3
    cp python "$HOST_PYTHON/python"
    make distclean 2>/dev/null || true
fi

# Step 3: Configure for MerlionOS (static, musl)
echo "[3/5] Configuring CPython for MerlionOS..."
cd "$PYTHON_DIR"

CC="${CC:-gcc}"
if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
    CC="x86_64-linux-musl-gcc"
    if ! command -v $CC &>/dev/null; then
        CC="x86_64-linux-gnu-gcc"
    fi
    if ! command -v $CC &>/dev/null; then
        echo "WARNING: No x86_64 cross-compiler. Skipping build."
        exit 0
    fi
fi

# Disable modules that need unavailable libraries
cat > Modules/Setup.local << 'EOF'
# MerlionOS: disable modules requiring missing libraries
*disabled*
_ctypes
_decimal
_dbm
_gdbm
_lzma
_bz2
_tkinter
_curses
_curses_panel
readline
nis
ossaudiodev
spwd
EOF

./configure \
    --host=x86_64-linux-musl \
    --build=$(gcc -dumpmachine 2>/dev/null || echo x86_64-linux-gnu) \
    --prefix=/usr/local \
    --with-build-python="$HOST_PYTHON/python" \
    --disable-shared \
    --disable-ipv6 \
    --without-ensurepip \
    --without-doc-strings \
    CC="$CC" \
    CFLAGS="-static -O2 --sysroot=$SYSROOT -I$SYSROOT/include -DNDEBUG" \
    LDFLAGS="-static -L$SYSROOT/lib" \
    LIBS="-lc" \
    ac_cv_file__dev_ptmx=no \
    ac_cv_file__dev_ptc=no \
    2>&1 | tail -10

# Step 4: Build
echo "[4/5] Building CPython (this takes a few minutes)..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) \
    LINKFORSHARED=" " \
    2>&1 | tail -10

# Step 5: Copy binary
echo "[5/5] Packaging..."
if [ -f python ]; then
    cp python "$SCRIPT_DIR/python3-merlionos"
    strip "$SCRIPT_DIR/python3-merlionos" 2>/dev/null || true
    echo ""
    echo "=== CPython built for MerlionOS ==="
    file "$SCRIPT_DIR/python3-merlionos"
    ls -lh "$SCRIPT_DIR/python3-merlionos"
    echo ""
    echo "Run on MerlionOS:"
    echo "  merlion> run-user python3"
    echo ""
    echo "Interactive:"
    echo '  >>> print("Hello from Python on MerlionOS!")'
    echo '  >>> import sys; print(sys.platform)  # → merlionos'
else
    echo ""
    echo "Build did not produce binary."
    echo "Check build logs for details."
fi
