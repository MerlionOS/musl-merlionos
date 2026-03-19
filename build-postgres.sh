#!/bin/bash
#
# Build PostgreSQL for MerlionOS.
#
# PostgreSQL is pure C. Needs musl libc.
# Data stored in VFS (in-memory — no persistence across reboot).
#
# Prerequisites: run ./build.sh first (musl sysroot)
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SYSROOT="$SCRIPT_DIR/sysroot"
PG_DIR="$SCRIPT_DIR/postgres-upstream"
PG_VERSION="${1:-17.2}"

echo "=== Building PostgreSQL $PG_VERSION for MerlionOS ==="

if [ ! -f "$SYSROOT/lib/libc.a" ]; then
    echo "ERROR: musl not built. Run ./build.sh first."
    exit 1
fi

# Step 1: Download
if [ ! -d "$PG_DIR" ]; then
    echo "[1/4] Downloading PostgreSQL $PG_VERSION..."
    curl -sL "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.bz2" | tar xj
    mv "postgresql-$PG_VERSION" "$PG_DIR"
else
    echo "[1/4] PostgreSQL source already present"
fi

# Step 2: Configure
echo "[2/4] Configuring..."
cd "$PG_DIR"

CC="${CC:-gcc}"
if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
    CC="x86_64-linux-musl-gcc"
    command -v $CC &>/dev/null || CC="musl-gcc"
    command -v $CC &>/dev/null || CC="x86_64-linux-gnu-gcc"
fi

./configure \
    --prefix=/usr/local/pgsql \
    --without-readline \
    --without-zlib \
    --without-icu \
    --without-openssl \
    --without-pam \
    --without-ldap \
    --without-libxml \
    --without-libxslt \
    CC="$CC" \
    CFLAGS="-static -O2 --sysroot=$SYSROOT -I$SYSROOT/include" \
    LDFLAGS="-static -L$SYSROOT/lib" \
    2>&1 | tail -10

# Step 3: Build
echo "[3/4] Building (this takes a few minutes)..."
make -j$(nproc 2>/dev/null || echo 4) -C src/backend 2>&1 | tail -5
make -j$(nproc 2>/dev/null || echo 4) -C src/bin/psql 2>&1 | tail -5
make -j$(nproc 2>/dev/null || echo 4) -C src/bin/initdb 2>&1 | tail -5

# Step 4: Copy
echo "[4/4] Packaging..."
for bin in src/backend/postgres src/bin/psql/psql src/bin/initdb/initdb; do
    if [ -f "$bin" ]; then
        name=$(basename "$bin")
        cp "$bin" "$SCRIPT_DIR/${name}-merlionos"
        strip "$SCRIPT_DIR/${name}-merlionos" 2>/dev/null || true
    fi
done

echo ""
echo "=== PostgreSQL built for MerlionOS ==="
ls -lh "$SCRIPT_DIR/"*-merlionos 2>/dev/null | grep -E "postgres|psql|initdb"
echo ""
echo "Run on MerlionOS:"
echo "  merlion> run-user initdb"
echo "  merlion> run-user postgres"
echo "  merlion> run-user psql"
echo ""
echo "Note: VFS is in-memory — data does not persist across reboot."
