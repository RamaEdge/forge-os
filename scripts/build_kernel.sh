#!/bin/bash
# Build Linux kernel for ForgeOS using pre-downloaded source
# Usage: build_kernel.sh <arch> <build_dir> <artifacts_dir>

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load centralized versions
. "$PROJECT_ROOT/scripts/versions.sh"

# Parameters
ARCH="${1:-aarch64}"
TOOLCHAIN="${2:-musl}"
ARTIFACTS_DIR="${3:-artifacts}"

# Build directory based on toolchain
BUILD_DIR="build/kernel-${TOOLCHAIN}"

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
DOWNLOADS_DIR="$PROJECT_ROOT/packages/downloads"
KERNEL_OUTPUT="$ARTIFACTS_DIR/kernel/$ARCH"

# Cross-compilation settings
if [[ "$ARCH" == "aarch64" ]]; then
    CROSS_COMPILE="aarch64-linux-${TOOLCHAIN}-"
    KERNEL_ARCH="arm64"
else
    CROSS_COMPILE="${ARCH}-linux-${TOOLCHAIN}-"
    KERNEL_ARCH="$ARCH"
fi

# Set up toolchain PATH
TOOLCHAIN_DIR="$ARTIFACTS_DIR/toolchain/$ARCH-$TOOLCHAIN/bin"
if [[ -d "$TOOLCHAIN_DIR" ]]; then
    export PATH="$TOOLCHAIN_DIR:$PATH"
    log_info "Added toolchain to PATH: $TOOLCHAIN_DIR"
else
    log_error "Toolchain directory not found: $TOOLCHAIN_DIR"
    log_info "Please run 'make toolchain' first"
    exit 1
fi

log_info "Building Linux kernel for $ARCH"
log_info "Build directory: $BUILD_DIR"
log_info "Output directory: $KERNEL_OUTPUT"
log_info "Cross-compile: $CROSS_COMPILE"

# Check for required packages
kernel_tar="$DOWNLOADS_DIR/linux-${LINUX_VERSION}.tar.xz"
if [[ ! -f "$kernel_tar" ]]; then
    log_error "Kernel source not found: $kernel_tar"
    log_info "Please run 'make download-packages' first"
    exit 1
fi

# Create build directories
mkdir -p "$BUILD_DIR"
mkdir -p "$KERNEL_OUTPUT"

# Check if kernel already exists
if [[ -f "$KERNEL_OUTPUT/Image" ]]; then
    log_success "Kernel already exists at $KERNEL_OUTPUT"
    log_info "Skipping build (use 'make clean' to rebuild)"
    exit 0
fi

# Clean build directory to prevent conflicts
log_info "Cleaning build directory to prevent conflicts..."
rm -rf "$BUILD_DIR/linux" "$BUILD_DIR/linux-${LINUX_VERSION}"

# Set up environment BEFORE extracting kernel source
export ARCH="$KERNEL_ARCH"
export CROSS_COMPILE="$CROSS_COMPILE"
export CC="${CROSS_COMPILE}gcc"
export CXX="${CROSS_COMPILE}g++"
export INSTALL_PATH="$KERNEL_OUTPUT"
export INSTALL_MOD_PATH="$KERNEL_OUTPUT"

# Ensure PATH includes toolchain and export to all subprocesses
export PATH="$TOOLCHAIN_DIR:$PATH"
log_info "Exported toolchain PATH: $TOOLCHAIN_DIR"

# Extract kernel source
log_info "Extracting kernel source..."
tar -xf "$kernel_tar" -C "$BUILD_DIR"
mv "$BUILD_DIR/linux-${LINUX_VERSION}" "$BUILD_DIR/linux"

# Configure kernel
log_info "Configuring kernel..."
kernel_dir="$BUILD_DIR/linux"

# Use our hardened config if available
if [[ -f "$PROJECT_ROOT/kernel/configs/${ARCH}_defconfig" ]]; then
    log_info "Using hardened config: ${ARCH}_defconfig"
    cp "$PROJECT_ROOT/kernel/configs/${ARCH}_defconfig" "$kernel_dir/.config"
else
    log_info "Using default config for $ARCH"
    pushd "$kernel_dir"
    # Ensure all environment variables are properly exported
    env PATH="$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake defconfig
    popd
fi

# Apply any patches
if [[ -d "$PROJECT_ROOT/kernel/patches" ]]; then
    log_info "Applying kernel patches..."
    for patch in "$PROJECT_ROOT/kernel/patches"/*.patch; do
        if [[ -f "$patch" ]]; then
            log_info "Applying patch: $(basename "$patch")"
            pushd "$kernel_dir"
            if ! patch -p1 < "$patch"; then
                log_warning "Patch $(basename "$patch") failed to apply - continuing without it"
                log_info "This may be due to kernel version incompatibility"
            fi
            popd
        fi
    done
fi

# Build kernel
log_info "Building kernel (this may take a while)..."
pushd "$kernel_dir"
# Ensure all environment variables are properly exported for build
env PATH="$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake -j$(nproc 2>/dev/null || echo 4)

# Install kernel
log_info "Installing kernel..."
# Ensure all environment variables are properly exported for install
env PATH="$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake INSTALL_PATH="$KERNEL_OUTPUT" install
env PATH="$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake INSTALL_MOD_PATH="$KERNEL_OUTPUT" modules_install
popd

# Copy kernel image to output
if [[ -f "$kernel_dir/arch/$KERNEL_ARCH/boot/Image" ]]; then
    cp "$kernel_dir/arch/$KERNEL_ARCH/boot/Image" "$KERNEL_OUTPUT/"
    log_success "Kernel image copied to $KERNEL_OUTPUT/Image"
else
    log_error "Kernel image not found after build"
    exit 1
fi

# Copy config
if [[ -f "$kernel_dir/.config" ]]; then
    cp "$kernel_dir/.config" "$KERNEL_OUTPUT/config"
    log_success "Kernel config copied to $KERNEL_OUTPUT/config"
fi

log_success "Kernel build complete: $KERNEL_OUTPUT"

# Verify kernel image
if [[ -f "$KERNEL_OUTPUT/Image" ]]; then
    log_success "Kernel image created successfully"
    file "$KERNEL_OUTPUT/Image"
else
    log_error "Kernel image not found"
    exit 1
fi

# Clean up build directory (keep only artifacts in artifacts/)
log_info "Cleaning up build directory..."
rm -rf "$BUILD_DIR/linux"
log_success "Build directory cleaned up - all outputs moved to artifacts/"
