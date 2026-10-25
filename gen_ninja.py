#!/usr/bin/env python3
"""xbps 包：把已编好的静态 xbps 工具打包（data-only，无 build）。"""
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT  = ROOT / "out"

PKG = {
    "pkgname": "xbps",
    "pkgver":  "0.60.7_1",
    "arch":    "x86_64",
    "desc":    "XBPS package manager",
    "deps":    "",
    "data": [
        ("out/xbps-create",  "apps/system/xbps-create"),
        ("out/xbps-install", "apps/system/xbps-install"),
        ("out/xbps-query",   "apps/system/xbps-query"),
        ("out/xbps-rindex",  "apps/system/xbps-rindex"),
        ("out/xbps-remove",  "apps/system/xbps-remove"),
        ("out/xbps-pkgdb",   "apps/system/xbps-pkgdb"),
    ],
}


def esc(p):
    return str(p).replace("$", "$$").replace(":", "$:").replace(" ", "$ ")


def main():
    out  = OUT / f"{PKG['pkgname']}-{PKG['pkgver']}.{PKG['arch']}.xbps"
    args = f"-A {PKG['arch']} -n {PKG['pkgname']}-{PKG['pkgver']} -s \"{PKG['desc']}\""
    if PKG.get("deps"):
        args += f" -D \"{PKG['deps']}\""

    files = [(s, d) for s, d in PKG["data"]]

    cmd = "rm -rf .pkg"
    for src, dst in files:
        cmd += f" && mkdir -p .pkg/$$(dirname {dst}) && cp {src} .pkg/{dst}"
    cmd += f" && cd out && xbps-create --compression gzip {args} ../.pkg"

    L = ["# xbps 包（静态工具，data-only）", "ninja_required_version = 1.10"]
    L += ["rule package", f"  command = {cmd}", ""]
    L += [f"build {esc(out)}: package {' '.join(esc(s) for s, _ in files)}"]
    L += [f"build pack: phony {esc(out)}"]
    L += ["default pack"]
    L += ["rule clean", "  command = rm -rf out .pkg", "build clean: clean"]

    (ROOT / "build.ninja").write_text("\n".join(L) + "\n", encoding="utf-8")
    print("已生成 build.ninja（xbps）。用法：ninja pack")


if __name__ == "__main__":
    main()
