# AGENTS.md — leopard-xbps

## 铁律
- 用户态逻辑**禁止**写回 OpenXSKernel / OpenXJ380。
- 本仓库只产出静态用户态二进制 + 构建脚本；不碰内核、不碰引导。
- 依赖临时 stage 到 LeopardOS（make_image.sh），未来由 xbps 接管。

## 构建约定
- 目标：x86_64 静态 ELF，用 musl 交叉编译（musl-gcc）。
- 产物放 out/，命名与上游工具一致（xbps-create 等）。
- 依赖源码放 src/，构建中间产物放 deps/。
