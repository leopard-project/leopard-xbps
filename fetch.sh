#!/bin/sh
# fetch.sh — fetch all spike sources
# Notes:
#  1. musl comes from a GitHub mirror (musl.libc.org resolves to IPv6 only here and is unreachable)
#  2. the libressl git repo does not commit VERSION/symbol tables, so use the release tarball
set -eu
cd "$(dirname "$0")"
mkdir -p src

clone() { # clone <url> <dir>
  [ -d "src/$2" ] || git clone -q --depth 1 "$1" "src/$2"
}

clone https://github.com/ifduyue/musl.git             musl
clone https://github.com/void-linux/xbps.git          xbps
clone https://github.com/madler/zlib.git              zlib
clone https://github.com/tukaani-project/xz.git       xz
clone https://github.com/libarchive/libarchive.git    libarchive
clone https://github.com/facebook/zstd.git          zstd

if [ ! -d src/libressl ]; then
  curl -sSL --retry 3 -o src/libressl.tar.gz     https://github.com/libressl/portable/releases/download/v4.4.0/libressl-4.4.0.tar.gz
  tar xzf src/libressl.tar.gz -C src
  mv src/libressl-4.4.0 src/libressl
  rm src/libressl.tar.gz
fi

echo "[fetch] done"
