#!/bin/sh
# fetch.sh — 拉取 spike 全部源码
# 注意：
#  1. musl 走 GitHub 镜像（musl.libc.org 本机只解析 IPv6 且不通）
#  2. libressl 的 git 仓库不提交 VERSION/符号表，必须用 release tarball
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
