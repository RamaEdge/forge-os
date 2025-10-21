#!/bin/bash
# Build BusyBox for ForgeOS using pre-downloaded source
# Usage: build_busybox.sh <arch> <build_dir> <artifacts_dir>

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load centralized versions
. "$PROJECT_ROOT/scripts/versions.sh"

# Parameters
ARCH="${1:-aarch64}"
BUILD_DIR="${2:-build/busybox}"
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
BUSYBOX_OUTPUT="$ARTIFACTS_DIR/busybox/$ARCH"

# Cross-compilation settings
if [[ "$ARCH" == "aarch64" ]]; then
    CROSS_COMPILE="aarch64-linux-musl-"
else
    CROSS_COMPILE="${ARCH}-linux-musl-"
fi

# Set up toolchain PATH
TOOLCHAIN_DIR="$ARTIFACTS_DIR/toolchain/$ARCH-musl/bin"
if [[ -d "$TOOLCHAIN_DIR" ]]; then
    export PATH="$TOOLCHAIN_DIR:$PATH"
    log_info "Added toolchain to PATH: $TOOLCHAIN_DIR"
else
    log_error "Toolchain directory not found: $TOOLCHAIN_DIR"
    log_info "Please run 'make toolchain' first"
    exit 1
fi

log_info "Building BusyBox for $ARCH"
log_info "Build directory: $BUILD_DIR"
log_info "Output directory: $BUSYBOX_OUTPUT"
log_info "Cross-compile: $CROSS_COMPILE"

# Check for required packages
busybox_tar="$DOWNLOADS_DIR/busybox-${BUSYBOX_VERSION}.tar.bz2"
if [[ ! -f "$busybox_tar" ]]; then
    log_error "BusyBox source not found: $busybox_tar"
    log_info "Please run 'make download-packages' first"
    exit 1
fi

# Create build directories
mkdir -p "$BUILD_DIR"
mkdir -p "$BUSYBOX_OUTPUT"

# Check if BusyBox already exists
if [[ -f "$BUSYBOX_OUTPUT/busybox" ]]; then
    log_success "BusyBox already exists at $BUSYBOX_OUTPUT"
    log_info "Skipping build (use 'make clean' to rebuild)"
    exit 0
fi

# Extract BusyBox source
log_info "Extracting BusyBox source..."
tar -xf "$busybox_tar" -C "$BUILD_DIR"
mv "$BUILD_DIR/busybox-${BUSYBOX_VERSION}" "$BUILD_DIR/busybox"

# Set up environment
export ARCH="$ARCH"
export CROSS_COMPILE="$CROSS_COMPILE"

# Configure BusyBox
log_info "Configuring BusyBox..."
busybox_dir="$BUILD_DIR/busybox"

# Use our config if available
if [[ -f "$PROJECT_ROOT/userland/busybox/configs/busybox_defconfig" ]]; then
    log_info "Using ForgeOS config: busybox_defconfig"
    cp "$PROJECT_ROOT/userland/busybox/configs/busybox_defconfig" "$busybox_dir/.config"
else
    log_info "Using default config"
    pushd "$busybox_dir"
    PATH="$TOOLCHAIN_DIR:$PATH" gmake defconfig
    popd
fi

# Apply any patches
if [[ -d "$PROJECT_ROOT/userland/busybox/patches" ]]; then
    log_info "Applying BusyBox patches..."
    for patch in "$PROJECT_ROOT/userland/busybox/patches"/*.patch; do
        if [[ -f "$patch" ]]; then
            log_info "Applying patch: $(basename "$patch")"
            pushd "$busybox_dir"
            patch -p1 < "$patch"
            popd
        fi
    done
fi

# Build BusyBox
log_info "Building BusyBox (this may take a while)..."
pushd "$busybox_dir"
PATH="$TOOLCHAIN_DIR:$PATH" gmake -j$(nproc 2>/dev/null || echo 4)

# Install BusyBox
log_info "Installing BusyBox..."
PATH="$TOOLCHAIN_DIR:$PATH" gmake DESTDIR="" install
popd

# Copy BusyBox binary to output
if [[ -f "$busybox_dir/busybox" ]]; then
    cp "$busybox_dir/busybox" "$BUSYBOX_OUTPUT/"
    log_success "BusyBox binary copied to $BUSYBOX_OUTPUT/busybox"
else
    log_error "BusyBox binary not found after build"
    exit 1
fi

# Copy config
if [[ -f "$busybox_dir/.config" ]]; then
    cp "$busybox_dir/.config" "$BUSYBOX_OUTPUT/config"
    log_success "BusyBox config copied to $BUSYBOX_OUTPUT/config"
fi

log_success "BusyBox build complete: $BUSYBOX_OUTPUT"

# Verify BusyBox binary
if [[ -f "$BUSYBOX_OUTPUT/busybox" ]]; then
    log_success "BusyBox binary created successfully"
    file "$BUSYBOX_OUTPUT/busybox"
else
    log_error "BusyBox binary not found"
    exit 1
fi
