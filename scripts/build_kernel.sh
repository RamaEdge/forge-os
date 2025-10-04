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
BUILD_DIR="${2:-build/kernel}"
ARTIFACTS_DIR="${3:-artifacts}"

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
    CROSS_COMPILE="aarch64-linux-musl-"
    KERNEL_ARCH="arm64"
else
    CROSS_COMPILE="${ARCH}-linux-musl-"
    KERNEL_ARCH="$ARCH"
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

# Extract kernel source
log_info "Extracting kernel source..."
cd "$BUILD_DIR"
tar -xf "$kernel_tar"
mv "linux-${LINUX_VERSION}" linux

# Set up environment
export ARCH="$KERNEL_ARCH"
export CROSS_COMPILE="$CROSS_COMPILE"
export INSTALL_PATH="$KERNEL_OUTPUT"
export INSTALL_MOD_PATH="$KERNEL_OUTPUT"

# Configure kernel
log_info "Configuring kernel..."
cd linux

# Use our hardened config if available
if [[ -f "$PROJECT_ROOT/kernel/configs/${ARCH}_defconfig" ]]; then
    log_info "Using hardened config: ${ARCH}_defconfig"
    cp "$PROJECT_ROOT/kernel/configs/${ARCH}_defconfig" .config
else
    log_info "Using default config for $ARCH"
    gmake defconfig
fi

# Apply any patches
if [[ -d "$PROJECT_ROOT/kernel/patches" ]]; then
    log_info "Applying kernel patches..."
    for patch in "$PROJECT_ROOT/kernel/patches"/*.patch; do
        if [[ -f "$patch" ]]; then
            log_info "Applying patch: $(basename "$patch")"
            patch -p1 < "$patch"
        fi
    done
fi

# Build kernel
log_info "Building kernel (this may take a while)..."
gmake -j$(nproc 2>/dev/null || echo 4)

# Install kernel
log_info "Installing kernel..."
gmake install
gmake modules_install

# Copy kernel image to output
if [[ -f "arch/$KERNEL_ARCH/boot/Image" ]]; then
    cp "arch/$KERNEL_ARCH/boot/Image" "$KERNEL_OUTPUT/"
    log_success "Kernel image copied to $KERNEL_OUTPUT/Image"
else
    log_error "Kernel image not found after build"
    exit 1
fi

# Copy config
if [[ -f ".config" ]]; then
    cp ".config" "$KERNEL_OUTPUT/config"
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
