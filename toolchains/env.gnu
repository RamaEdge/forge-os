#!/bin/bash
# ForgeOS glibc toolchain environment setup
# Source this file to set up the glibc cross-compilation environment

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load version information
if [[ -f "$PROJECT_ROOT/versions.sh" ]]; then
    source "$PROJECT_ROOT/versions.sh"
fi

# Default architecture
ARCH="${ARCH:-aarch64}"

# Toolchain configuration
TOOLCHAIN_TYPE="gnu"
CROSS_COMPILE="${ARCH}-linux-gnu-"
SYSROOT="${PROJECT_ROOT}/toolchains/output/${ARCH}-linux-gnu"

# Toolchain paths
TOOLCHAIN_BIN="${PROJECT_ROOT}/toolchains/output/${ARCH}-linux-gnu/bin"
TOOLCHAIN_LIB="${PROJECT_ROOT}/toolchains/output/${ARCH}-linux-gnu/lib"
TOOLCHAIN_INCLUDE="${PROJECT_ROOT}/toolchains/output/${ARCH}-linux-gnu/include"

# Export environment variables
export ARCH
export TOOLCHAIN_TYPE
export CROSS_COMPILE
export SYSROOT
export TOOLCHAIN_BIN
export TOOLCHAIN_LIB
export TOOLCHAIN_INCLUDE

# Update PATH
if [[ -d "$TOOLCHAIN_BIN" ]]; then
    export PATH="$TOOLCHAIN_BIN:$PATH"
fi

# Compiler flags
export CC="${CROSS_COMPILE}gcc"
export CXX="${CROSS_COMPILE}g++"
export AR="${CROSS_COMPILE}ar"
export STRIP="${CROSS_COMPILE}strip"
export RANLIB="${CROSS_COMPILE}ranlib"
export NM="${CROSS_COMPILE}nm"
export OBJCOPY="${CROSS_COMPILE}objcopy"
export OBJDUMP="${CROSS_COMPILE}objdump"
export READELF="${CROSS_COMPILE}readelf"

# Build flags for reproducible builds
export CFLAGS="-Os -fno-stack-protector -fno-unwind-tables -fno-asynchronous-unwind-tables"
export CXXFLAGS="-Os -fno-stack-protector -fno-unwind-tables -fno-asynchronous-unwind-tables"
export LDFLAGS="-Wl,--build-id=sha1"

# Print environment info if sourced interactively
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ForgeOS glibc toolchain environment:"
    echo "  Architecture: $ARCH"
    echo "  Cross-compile: $CROSS_COMPILE"
    echo "  Sysroot: $SYSROOT"
    echo "  Toolchain bin: $TOOLCHAIN_BIN"
    echo "  CC: $CC"
    echo "  CXX: $CXX"
    echo ""
    echo "Environment variables exported. Use 'source $0' to load in scripts."
fi
