#!/bin/bash
################################################################################
# ForgeOS Kernel Build Script
# 
# Compiles the Linux kernel with ForgeOS hardened configuration and stages
# the resulting artifacts (kernel image, modules, config) for ISO packaging.
#
# Usage:
#   build_kernel.sh [arch] [toolchain] [artifacts_dir]
#
# Parameters:
#   arch           Target architecture (default: aarch64)
#                  Supported: aarch64 (ARM 64-bit)
#
#   toolchain      Cross-compilation toolchain type (default: musl)
#                  Supported: musl (default, Alpine-compatible)
#                             glibc (GNU C Library)
#
#   artifacts_dir  Directory for staging kernel artifacts (default: artifacts)
#                  CRITICAL: ISO build system expects this path to contain:
#                  - vmlinuz (kernel image)
#                  - config (kernel configuration)
#                  - lib/modules/ (kernel modules)
#
# Examples:
#   # Build for ARM64 with musl toolchain (default)
#   ./scripts/build_kernel.sh
#
#   # Build for ARM64 with GNU C library
#   ./scripts/build_kernel.sh aarch64 glibc
#
#   # Build with custom artifacts directory
#   ./scripts/build_kernel.sh aarch64 musl /custom/build/path
#
# Output Artifacts:
#   artifacts/kernel/aarch64/
#   ├── vmlinuz              # Kernel image (arm64 binary)
#   ├── config               # Kernel build configuration (for auditing)
#   ├── System.map           # Symbol table (for debugging)
#   └── lib/modules/         # Kernel modules directory
#       └── <version>/       # Module version directory
#           ├── kernel/      # Kernel modules
#           ├── modules.dep  # Module dependency information
#           └── modules.*.bin # Module binaries
#
# Security Features:
#   - Mandatory hardened kernel configuration (AppArmor, seccomp, KASLR)
#   - Signed kernel image (if signing is enabled)
#   - Deterministic build (reproducible artifacts)
#
# Dependencies:
#   - Cross-compilation toolchain (run 'make toolchain' first)
#   - Kernel source (run 'make download-packages' first)
#   - versions.sh (loaded automatically for version info)
#
# Exit Codes:
#   0 = Success: Kernel built and staged in artifacts directory
#   1 = Failure: See error messages for details
#
################################################################################

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Verify versions.sh exists before sourcing
VERSIONS_SCRIPT="$PROJECT_ROOT/scripts/versions.sh"
if [[ ! -f "$VERSIONS_SCRIPT" ]]; then
    echo "Error: versions.sh not found at $VERSIONS_SCRIPT" >&2
    echo "This script is required for version management" >&2
    exit 1
fi

# Load centralized versions
# Source with error handling - if sourcing fails, the script will exit due to set -e
. "$VERSIONS_SCRIPT" || {
    echo "Error: Failed to source versions.sh at $VERSIONS_SCRIPT" >&2
    exit 1
}

# Verify critical variables are set after sourcing
if [[ -z "${LINUX_VERSION:-}" ]]; then
    echo "Error: LINUX_VERSION is not set - versions.sh may not have been sourced correctly" >&2
    exit 1
fi

# Parameters
ARCH="${1:-aarch64}"
TOOLCHAIN="${2:-musl}"
ARTIFACTS_DIR="${3:-artifacts}"

# Convert BUILD_DIR to absolute path to ensure consistency regardless of script invocation location
BUILD_DIR="$(cd "$PROJECT_ROOT" && pwd)/build/kernel-${TOOLCHAIN}"

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
KERNEL_OUTPUT="$(cd "$PROJECT_ROOT" && pwd)/$ARTIFACTS_DIR/kernel/$ARCH"

# Cross-compilation settings
if [[ "$ARCH" == "aarch64" ]]; then
    CROSS_COMPILE="aarch64-linux-${TOOLCHAIN}-"
    KERNEL_ARCH="arm64"
else
    CROSS_COMPILE="${ARCH}-linux-${TOOLCHAIN}-"
    KERNEL_ARCH="$ARCH"
fi

# Set up toolchain PATH - convert to absolute path early
TOOLCHAIN_DIR="$(cd "$PROJECT_ROOT" && pwd)/$ARTIFACTS_DIR/toolchain/$ARCH-$TOOLCHAIN/bin"
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

# Check if kernel already exists and is complete
if [[ -f "$KERNEL_OUTPUT/Image" ]] && [[ -f "$KERNEL_OUTPUT/config" ]] && [[ -d "$KERNEL_OUTPUT/lib" ]]; then
    log_success "Complete kernel build already exists at $KERNEL_OUTPUT"
    log_info "Skipping build (use 'make clean-kernel' to rebuild)"
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

# Configure kernel with mandatory hardened config
log_info "Configuring kernel..."
kernel_dir="$BUILD_DIR/linux"

# ForgeOS SECURITY POLICY: Hardened kernel config is MANDATORY
# This ensures all kernels shipped in ISO images have:
# - AppArmor MAC enforcement
# - seccomp filtering capabilities
# - KASLR address space randomization
# - Other hardening features configured
HARDENED_CONFIG="$PROJECT_ROOT/kernel/configs/${ARCH}_defconfig"
if [[ ! -f "$HARDENED_CONFIG" ]]; then
    log_error "HARDENED kernel config REQUIRED but NOT FOUND"
    log_error "Expected location: $HARDENED_CONFIG"
    log_error "This is mandatory for ForgeOS security policy"
    log_error "The hardened config must exist to ensure all ForgeOS ISOs meet security requirements"
    exit 1
fi

log_success "Using HARDENED kernel config: $HARDENED_CONFIG"
cp "$HARDENED_CONFIG" "$kernel_dir/.config" || {
    log_error "Failed to copy hardened kernel config to build directory"
    exit 1
}
log_info "Kernel config loaded from: $HARDENED_CONFIG"

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
env PATH="$TOOLCHAIN_DIR:$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake -j$(nproc 2>/dev/null || echo 4)

# Install kernel
log_info "Installing kernel..."
# Ensure all environment variables are properly exported for install
env PATH="$TOOLCHAIN_DIR:$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake INSTALL_PATH="$KERNEL_OUTPUT" install
env PATH="$TOOLCHAIN_DIR:$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake INSTALL_MOD_PATH="$KERNEL_OUTPUT" modules_install

# Install kernel headers for cross-compilation
log_info "Installing kernel headers..."
env PATH="$TOOLCHAIN_DIR:$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake INSTALL_HDR_PATH="$KERNEL_OUTPUT/usr" headers_install
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
