#!/bin/bash
# ForgeOS Toolchain Build Script
# Builds cross-compilation toolchains (musl/glibc)
# Implements THE-46 (Toolchains)

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load centralized versions
source "$PROJECT_ROOT/scripts/versions.sh"

# Parameters
ARCH="${1:-aarch64}"
TOOLCHAIN="${2:-musl}"
ARTIFACTS_DIR="${3:-$PROJECT_ROOT/artifacts}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

# Build configuration
BUILD_DIR="$PROJECT_ROOT/build/toolchain"
DOWNLOADS_DIR="$PROJECT_ROOT/packages/downloads"
TOOLCHAIN_OUTPUT="$ARTIFACTS_DIR/toolchain/$ARCH-$TOOLCHAIN"

# Cross-compilation settings
if [[ "$TOOLCHAIN" == "musl" ]]; then
    TARGET="$ARCH-linux-musl"
    CROSS_COMPILE="$TARGET-"
else
    TARGET="$ARCH-linux-gnu"
    CROSS_COMPILE="$TARGET-"
fi

log_info "Building $TOOLCHAIN toolchain for $ARCH"
log_info "Target: $TARGET"
log_info "Build directory: $BUILD_DIR"
log_info "Output directory: $TOOLCHAIN_OUTPUT"

# Create build directories
mkdir -p "$BUILD_DIR"
mkdir -p "$TOOLCHAIN_OUTPUT"

# Check if toolchain already exists
if [[ -f "$TOOLCHAIN_OUTPUT/bin/$CROSS_COMPILE"gcc ]]; then
    log_success "Toolchain already exists at $TOOLCHAIN_OUTPUT"
    log_info "Skipping build (use 'make clean' to rebuild)"
    exit 0
fi

# Build musl toolchain using pre-downloaded packages
build_musl_toolchain() {
    log_info "Building musl toolchain using pre-downloaded packages..."
    
    # Check for required packages
    local binutils_tar="$DOWNLOADS_DIR/binutils-${BINUTILS_VERSION}.tar.xz"
    local gcc_tar="$DOWNLOADS_DIR/gcc-${GCC_VERSION}.tar.xz"
    local musl_tar="$DOWNLOADS_DIR/musl-${MUSL_VERSION}.tar.gz"
    local linux_tar="$DOWNLOADS_DIR/linux-${LINUX_VERSION}.tar.xz"
    
    for pkg in "$binutils_tar" "$gcc_tar" "$musl_tar" "$linux_tar"; do
        if [[ ! -f "$pkg" ]]; then
            log_error "Required package not found: $pkg"
            log_info "Please run 'make download-packages' first"
            exit 1
        fi
    done
    
    # Create build directories
    local build_root="$BUILD_DIR/musl-toolchain"
    mkdir -p "$build_root"
    cd "$build_root"
    
    # Extract packages
    log_info "Extracting toolchain packages..."
    tar -xf "$binutils_tar"
    tar -xf "$gcc_tar"
    tar -xf "$musl_tar"
    tar -xf "$linux_tar"
    
    # Set up environment
    export PATH="$TOOLCHAIN_OUTPUT/bin:$PATH"
    export PREFIX="$TOOLCHAIN_OUTPUT"
    
    # Build binutils first
    log_info "Building binutils..."
    cd "binutils-${BINUTILS_VERSION}"
    mkdir -p build
    cd build
    ../configure \
        --target="$TARGET" \
        --prefix="$(realpath "$TOOLCHAIN_OUTPUT")" \
        --disable-nls \
        --disable-werror \
        --disable-multilib
gmake -j$(nproc 2>/dev/null || echo 4)
gmake install
    cd ../..
    
    # Build musl
    log_info "Building musl..."
    cd "musl-${MUSL_VERSION}"
    ./configure \
        --target="$TARGET" \
        --prefix="$(realpath "$TOOLCHAIN_OUTPUT")/$TARGET" \
        --disable-shared
gmake -j$(nproc 2>/dev/null || echo 4)
gmake install
    cd ..
    
    # Build GCC (stage 1 - bootstrap)
    log_info "Building GCC (stage 1)..."
    cd "gcc-${GCC_VERSION}"
    mkdir -p build
    cd build
    ../configure \
        --target="$TARGET" \
        --prefix="$(realpath "$TOOLCHAIN_OUTPUT")" \
        --enable-languages=c \
        --disable-libssp \
        --disable-libgomp \
        --disable-libmudflap \
        --disable-libsanitizer \
        --disable-libatomic \
        --disable-libquadmath \
        --disable-multilib \
        --with-sysroot="$(realpath "$TOOLCHAIN_OUTPUT")/$TARGET" \
        --with-newlib \
        --disable-shared \
        --disable-threads \
        --disable-libstdcxx-pch
    make -j$(nproc 2>/dev/null || echo 4) all-gcc
    gmake install-gcc
    cd ../..
    
    log_success "musl toolchain built successfully"
}

# Build glibc toolchain using pre-downloaded packages
build_glibc_toolchain() {
    log_info "Building glibc toolchain using pre-downloaded packages..."
    
    # Check for required packages
    local binutils_tar="$DOWNLOADS_DIR/binutils-${BINUTILS_VERSION}.tar.xz"
    local gcc_tar="$DOWNLOADS_DIR/gcc-${GCC_VERSION}.tar.xz"
    local glibc_tar="$DOWNLOADS_DIR/glibc-${GLIBC_VERSION}.tar.xz"
    local linux_tar="$DOWNLOADS_DIR/linux-${LINUX_VERSION}.tar.xz"
    
    for pkg in "$binutils_tar" "$gcc_tar" "$glibc_tar" "$linux_tar"; do
        if [[ ! -f "$pkg" ]]; then
            log_error "Required package not found: $pkg"
            log_info "Please run 'make download-packages' first"
            exit 1
        fi
    done
    
    # Create build directories
    local build_root="$BUILD_DIR/glibc-toolchain"
    mkdir -p "$build_root"
    cd "$build_root"
    
    # Extract packages
    log_info "Extracting toolchain packages..."
    tar -xf "$binutils_tar"
    tar -xf "$gcc_tar"
    tar -xf "$glibc_tar"
    tar -xf "$linux_tar"
    
    # Set up environment
    export PATH="$TOOLCHAIN_OUTPUT/bin:$PATH"
    export PREFIX="$TOOLCHAIN_OUTPUT"
    
    # Build binutils first
    log_info "Building binutils..."
    cd "binutils-${BINUTILS_VERSION}"
    mkdir -p build
    cd build
    ../configure \
        --target="$TARGET" \
        --prefix="$(realpath "$TOOLCHAIN_OUTPUT")" \
        --disable-nls \
        --disable-werror \
        --disable-multilib
gmake -j$(nproc 2>/dev/null || echo 4)
gmake install
    cd ../..
    
    # Build glibc headers
    log_info "Building glibc headers..."
    cd "glibc-${GLIBC_VERSION}"
    mkdir -p build
    cd build
    ../configure \
        --target="$TARGET" \
        --prefix="$(realpath "$TOOLCHAIN_OUTPUT")/$TARGET" \
        --with-headers="$(realpath ../../linux-${LINUX_VERSION}/include)" \
        --disable-multilib
    gmake install-headers
    cd ../..
    
    # Build GCC (stage 1 - bootstrap)
    log_info "Building GCC (stage 1)..."
    cd "gcc-${GCC_VERSION}"
    mkdir -p build
    cd build
    ../configure \
        --target="$TARGET" \
        --prefix="$(realpath "$TOOLCHAIN_OUTPUT")" \
        --enable-languages=c \
        --disable-libssp \
        --disable-libgomp \
        --disable-libmudflap \
        --disable-libsanitizer \
        --disable-libatomic \
        --disable-libquadmath \
        --disable-multilib \
        --with-sysroot="$(realpath "$TOOLCHAIN_OUTPUT")/$TARGET" \
        --with-newlib \
        --disable-shared \
        --disable-threads \
        --disable-libstdcxx-pch
    make -j$(nproc 2>/dev/null || echo 4) all-gcc
    gmake install-gcc
    cd ../..
    
    log_success "glibc toolchain built successfully"
}

# Main build logic
case "$TOOLCHAIN" in
    "musl")
        build_musl_toolchain
        ;;
    "gnu"|"glibc")
        build_glibc_toolchain
        ;;
    *)
        log_error "Unknown toolchain: $TOOLCHAIN"
        log_info "Supported toolchains: musl, gnu, glibc"
        exit 1
        ;;
esac

# Verify toolchain
log_info "Verifying toolchain..."
if [[ -f "$TOOLCHAIN_OUTPUT/bin/$CROSS_COMPILE"gcc ]]; then
    "$TOOLCHAIN_OUTPUT/bin/$CROSS_COMPILE"gcc --version | head -1
    log_success "Toolchain verification complete"
else
    log_error "Toolchain verification failed"
    exit 1
fi

log_success "Toolchain build complete: $TOOLCHAIN_OUTPUT"
