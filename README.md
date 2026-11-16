# leopard-xbps — xbps 用户态移植 spike

把 Void Linux 的 xbps 包管理器作为**纯用户态静态二进制**移植进 LeopardOS，
零内核改动。这是可行性验证（spike），验证通过后再转正式打包体系。

## 铁律（重要）
1. **绝不**把用户态业务逻辑写回 leopard-xsk —— 它是纯内核，不能再变成 OpenXJ380。
2. **绝不**在 OpenXJ380 上开发。
3. 依赖先在 LeopardOS 里临时手工 stage（走 make_image.sh），未来交给 xbps 自己管理。

## 目标
证明：musl + libarchive + xbps 能在 leopard-xsk 的 POSIX syscall 面上静态跑起来。
最小闭环：
```
xbps-create 打个 .xbps → 本地 file:// 仓库 → xbps-install 装上
```

## 依赖链（都要静态、对 musl）
```
musl(工具链+libc) → zlib → liblzma/xz → libarchive → libressl(签名) → xbps
```

## 目录
- `src/`     拉取的源码（musl / xbps / 各依赖）
- `toolchain/` musl 交叉工具链（musl-gcc）
- `deps/`     依赖静态库构建产物
- `out/`      最终静态 ELF（xbps-create / xbps-install / ...）

## 构建
```
./fetch.sh    # 拉源码（GitHub 镜像）
./build.sh    # musl → deps → xbps
```

## 网络注意
本机 musl.libc.org 只解析 IPv6 且 IPv6 不通，musl 源码走 GitHub 镜像拉取。
