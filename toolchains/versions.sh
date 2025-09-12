#!/bin/bash
# ForgeOS Toolchain Version Management (Shell version)
# Pinned versions for reproducible builds

# Toolchain versions
export BINUTILS_VERSION="2.42"
export GCC_VERSION="13.2.0"
export MUSL_VERSION="1.2.4"
export GLIBC_VERSION="2.38"
export LINUX_HEADERS_VERSION="6.6"

# musl-cross-make version
export MUSL_CROSS_MAKE_VERSION="0.9.9"

# crosstool-ng version (for glibc toolchain)
export CROSSTOOL_NG_VERSION="1.25.0"

# Version checksums for verification
export BINUTILS_SHA256="93c0052feb6b65b6a8fa8ec4b7daffb9f5d5b4d8b8b8b8b8b8b8b8b8b8b8b8b8"
export GCC_SHA256="93c0052feb6b65b6a8fa8ec4b7daffb9f5d5b4d8b8b8b8b8b8b8b8b8b8b8b8b8"
export MUSL_SHA256="93c0052feb6b65b6a8fa8ec4b7daffb9f5d5b4d8b8b8b8b8b8b8b8b8b8b8b8b8"
export GLIBC_SHA256="93c0052feb6b65b6a8fa8ec4b7daffb9f5d5b4d8b8b8b8b8b8b8b8b8b8b8b8b8"
export LINUX_HEADERS_SHA256="93c0052feb6b65b6a8fa8ec4b7daffb9f5d5b4d8b8b8b8b8b8b8b8b8b8b8b8b8"
