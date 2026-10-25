#!/bin/sh
# build.sh — musl 工具链 → 依赖 → xbps 全静态构建
# 用法：./fetch.sh && ./build.sh
set -eu
cd "$(dirname "$0")"
ROOT="$(pwd)"
TC="$ROOT/toolchain"
PFX="$ROOT/deps/prefix"
NPROC="$(nproc)"

# ---------- 1. musl 静态工具链 ----------
if [ ! -x "$TC/bin/musl-gcc" ]; then
  cd src/musl
  ./configure --prefix="$TC" --disable-shared >/dev/null
  make -j"$NPROC" >/dev/null
  make install >/dev/null
  cd "$ROOT"
fi
MUSL_GCC="$TC/bin/musl-gcc"
echo "[build] musl toolchain OK"

# ---------- 2. zlib ----------
if [ ! -f "$PFX/lib/libz.a" ]; then
  cd src/zlib
  CC="$MUSL_GCC" CFLAGS="-O2" ./configure --static --prefix="$PFX" >/dev/null
  make -j"$NPROC" >/dev/null
  make install >/dev/null
  cd "$ROOT"
fi
echo "[build] zlib OK"

# ---------- 3. liblzma (xz) ----------
if [ ! -f "$PFX/lib/liblzma.a" ]; then
  cd src/xz
  cmake -B build -DCMAKE_C_COMPILER="$MUSL_GCC" -DCMAKE_C_FLAGS="-O2" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF -DXZ_TOOL_XZ=OFF -DXZ_TOOL_XZDEC=OFF -DXZ_TOOL_LZMADEC=OFF \
    -DXZ_TOOL_LZMAINFO=OFF -DXZ_TOOL_SCRIPTS=OFF -DXZ_NLS=OFF -DXZ_DOC=OFF \
    -DCMAKE_INSTALL_PREFIX="$PFX" >/dev/null
  cmake --build build -j"$NPROC" >/dev/null
  cmake --install build >/dev/null
  cd "$ROOT"
fi
echo "[build] liblzma OK"

# ---------- 3.5 libzstd ----------
if [ ! -f "$PFX/lib/libzstd.a" ]; then
  cd src/zstd/lib
  make libzstd.a -j"$NPROC" CC="$MUSL_GCC" CFLAGS="-O2" >/dev/null
  mkdir -p "$PFX/lib" "$PFX/include"
  cp libzstd.a "$PFX/lib/"
  cp zstd.h zstd_errors.h zdict.h "$PFX/include/"
  cd "$ROOT"
fi
echo "[build] libzstd OK"

# ---------- 4. libarchive ----------
if [ ! -f "$PFX/lib/libarchive.a" ]; then
  cd src/libarchive
  export PKG_CONFIG_PATH="$PFX/lib/pkgconfig"
  cmake -B build -DCMAKE_C_COMPILER="$MUSL_GCC" -DCMAKE_C_FLAGS="-O2" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF -DCMAKE_PREFIX_PATH="$PFX" \
    -DENABLE_TEST=OFF -DENABLE_OPENSSL=OFF -DENABLE_LIBXML2=OFF -DENABLE_EXPAT=OFF \
    -DENABLE_PCREPOSIX=OFF -DENABLE_LIBB2=OFF -DENABLE_LZ4=OFF -DENABLE_ZSTD=ON \
    -DENABLE_LZO=OFF -DENABLE_MBEDTLS=OFF -DENABLE_NETTLE=OFF -DENABLE_CNG=OFF \
    -DENABLE_ICONV=OFF -DENABLE_BZip2=OFF -DENABLE_CAT=OFF -DENABLE_CPIO=OFF \
    -DCMAKE_INSTALL_PREFIX="$PFX" >/dev/null
  cmake --build build -j"$NPROC" >/dev/null
  cmake --install build >/dev/null
  cd "$ROOT"
fi
echo "[build] libarchive OK"

# ---------- 5. libressl ----------
if [ ! -f "$PFX/lib/libcrypto.a" ]; then
  cd src/libressl
  cmake -B build -DCMAKE_C_COMPILER="$MUSL_GCC" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF -DLIBRESSL_APPS=OFF -DLIBRESSL_TESTS=OFF \
    -DCMAKE_INSTALL_PREFIX="$PFX" >/dev/null
  cmake --build build -j"$NPROC" >/dev/null
  cmake --install build >/dev/null
  cd "$ROOT"
fi
echo "[build] libressl OK"

# ---------- 6. xbps（只编 .static，跳过 libxbps.so —— musl protected 符号不支持共享库） ----------
cd src/xbps
export PKG_CONFIG_PATH="$PFX/lib/pkgconfig"
# LeopardOS 运行时路径：配置 /system/etc/xbps.d、pkgdb /system/var/db/xbps、默认配置 /system/share/xbps.d
CC="$MUSL_GCC" ./configure --prefix=/system --sysconfdir=/system/etc --dbdir=/system/var/db/xbps --enable-static --disable-debug >/dev/null
make -C lib clean >/dev/null 2>&1
make -C lib libxbps.a -j"$NPROC" >/dev/null
mkdir -p "$ROOT/out"
for t in xbps-create xbps-install xbps-query xbps-rindex xbps-remove xbps-pkgdb; do
  make -C bin/$t clean >/dev/null 2>&1
  make -C bin/$t $t.static >/dev/null
  cp bin/$t/$t.static "$ROOT/out/$t"
done
cd "$ROOT"
# 打上 ELFOSABI_LINUX：OpenXSKernel 靠 EI_OSABI(字节7) 区分 Linux ABI 与 XAPI ABI
for t in xbps-create xbps-install xbps-query xbps-rindex xbps-remove xbps-pkgdb; do
    [ -f "$ROOT/out/$t" ] && printf '\003' | dd of="$ROOT/out/$t" bs=1 seek=7 conv=notrunc 2>/dev/null
done
echo "[build] patched ELF OSABI -> LINUX"
echo "[build] xbps tools OK -> out/"
ls -la out/
