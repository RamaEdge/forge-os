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

# Script configuration - Detect project root using git
# This ensures we find the correct root regardless of script location or invocation directory
if ! PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    # Fallback to script-based detection if not in a git repository
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    echo "Warning: Not in a git repository. Using fallback project root detection." >&2
    echo "Project root: $PROJECT_ROOT" >&2
fi

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

# Extract kernel source with validation
log_info "Extracting kernel source from $kernel_tar..."
log_info "Expected to extract to: $BUILD_DIR/linux-${LINUX_VERSION}"

# Validate tar file before extraction
if [[ ! -f "$kernel_tar" ]]; then
    log_error "Kernel source archive not found: $kernel_tar"
    log_error "This should not happen (already checked at line 75)"
    exit 1
fi

# Extract tar with explicit error checking
if ! tar -xf "$kernel_tar" -C "$BUILD_DIR"; then
    log_error "EXTRACTION FAILED: Failed to extract kernel source"
    log_error "Archive: $kernel_tar"
    log_error "Extract destination: $BUILD_DIR"
    log_error "This indicates:"
    log_error "  - Archive is corrupted or incomplete"
    log_error "  - Insufficient disk space"
    log_error "  - Permission denied on extract destination"
    log_error "  - Invalid tar file format"
    log_error ""
    log_error "To debug:"
    log_error "  1. Check archive integrity: tar -tzf $kernel_tar | head -20"
    log_error "  2. Check disk space: df -h $BUILD_DIR"
    log_error "  3. Redownload: make download-packages"
    exit 1
fi

# Validate expected directory structure exists
if [[ ! -d "$BUILD_DIR/linux-${LINUX_VERSION}" ]]; then
    log_error "EXTRACTION INCOMPLETE: Expected directory not found after extraction"
    log_error "Expected: $BUILD_DIR/linux-${LINUX_VERSION}"
    log_error "Archive: $kernel_tar"
    log_error ""
    log_error "Contents of $BUILD_DIR after extraction:"
    ls -lah "$BUILD_DIR" 2>/dev/null | sed 's/^/  /'
    log_error ""
    log_error "This indicates:"
    log_error "  - Archive structure differs from expected"
    log_error "  - Archive is for wrong Linux version"
    log_error "  - Archive is incomplete"
    log_error ""
    log_error "To fix:"
    log_error "  - Verify LINUX_VERSION=${LINUX_VERSION} is correct"
    log_error "  - Check packages.json for correct kernel URL"
    log_error "  - Redownload: make download-packages"
    exit 1
fi

# Rename extracted directory for consistency
if ! mv "$BUILD_DIR/linux-${LINUX_VERSION}" "$BUILD_DIR/linux"; then
    log_error "EXTRACTION FAILED: Could not rename extracted directory"
    log_error "From: $BUILD_DIR/linux-${LINUX_VERSION}"
    log_error "To:   $BUILD_DIR/linux"
    log_error "This indicates:"
    log_error "  - Permission denied"
    log_error "  - Destination already exists"
    log_error "  - Filesystem error"
    exit 1
fi

log_success "Kernel source extracted successfully to $BUILD_DIR/linux"

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

# Apply kernel patches - MANDATORY with fail-fast behavior
# All patches must apply cleanly. If any patch fails:
# - Build stops immediately (prevents corrupted kernel)
# - Clear error identifies which patch failed
# - Prevents interdependent patches from being in inconsistent state
if [[ -d "$PROJECT_ROOT/kernel/patches" ]]; then
    # Count patches to apply
    patch_count=0
    while IFS= read -r patch; do
        ((patch_count++)) || true
    done < <(find "$PROJECT_ROOT/kernel/patches" -maxdepth 1 -name "*.patch" -type f | sort)
    
    if [[ $patch_count -gt 0 ]]; then
        log_info "Applying $patch_count kernel patch(es)..."
        patch_num=0
        for patch in "$PROJECT_ROOT/kernel/patches"/*.patch; do
            if [[ -f "$patch" ]]; then
                ((patch_num++)) || true
                patch_name="$(basename "$patch")"
                log_info "[$patch_num/$patch_count] Applying patch: $patch_name"
                pushd "$kernel_dir" >/dev/null || {
                    log_error "Failed to enter kernel directory: $kernel_dir"
                    exit 1
                }
                
                # Apply patch with explicit error checking
                if ! patch -p1 < "$patch" 2>&1 | tee -a "$KERNEL_OUTPUT/patch-${patch_name}.log"; then
                    log_error "PATCH FAILED: $patch_name"
                    log_error "Patch file: $patch"
                    log_error "Kernel directory: $kernel_dir"
                    log_error "Patch output saved to: $KERNEL_OUTPUT/patch-${patch_name}.log"
                    log_error "This indicates either:"
                    log_error "  1. Kernel version mismatch (verify LINUX_VERSION)"
                    log_error "  2. Patch already applied"
                    log_error "  3. Patch designed for different kernel configuration"
                    log_error "  4. Interdependent patches not in correct order"
                    log_error ""
                    log_error "To fix:"
                    log_error "  - Check patch is for Linux ${LINUX_VERSION}"
                    log_error "  - Verify patch order in $PROJECT_ROOT/kernel/patches/"
                    log_error "  - Review patch-${patch_name}.log for details"
                    popd >/dev/null
                    exit 1
                fi
                
                log_success "Applied patch: $patch_name"
                popd >/dev/null || {
                    log_error "Failed to exit kernel directory"
                    exit 1
                }
            fi
        done
        log_success "All $patch_count patch(es) applied successfully"
    fi
elif [[ -d "$PROJECT_ROOT/kernel/patches" ]] && [[ $(find "$PROJECT_ROOT/kernel/patches" -maxdepth 1 -name "*.patch" -type f | wc -l) -eq 0 ]]; then
    log_info "No kernel patches found (patches directory is empty)"
fi

# Build kernel with intelligent parallel job handling
log_info "Building kernel (this may take a while)..."

# Determine parallel job count
# Priority: PARALLEL_JOBS env var > nproc > 1 (single-threaded fallback)
PARALLEL_JOBS="${PARALLEL_JOBS:-}"
if [[ -z "$PARALLEL_JOBS" ]]; then
    PARALLEL_JOBS=$(nproc 2>/dev/null || echo 1)
fi

# Validate PARALLEL_JOBS is a positive integer
if ! [[ "$PARALLEL_JOBS" =~ ^[0-9]+$ ]] || [[ $PARALLEL_JOBS -lt 1 ]]; then
    log_warning "Invalid PARALLEL_JOBS value: $PARALLEL_JOBS (must be positive integer)"
    PARALLEL_JOBS=1
fi

log_info "Building kernel with $PARALLEL_JOBS parallel job(s)"
log_info "To override: PARALLEL_JOBS=8 ./scripts/build_kernel.sh"

pushd "$kernel_dir"
# Ensure all environment variables are properly exported for build
# Try parallel build first, fall back to single-threaded if it fails
if ! env PATH="$TOOLCHAIN_DIR:$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake -j"$PARALLEL_JOBS"; then
    # Parallel build failed - try single-threaded as fallback
    log_warning "Parallel build with $PARALLEL_JOBS job(s) failed"
    log_info "Retrying kernel build with single-threaded mode (safer for low-resource systems)..."
    
    # Clean up any partial build artifacts
    log_info "Cleaning up partial build artifacts..."
    env PATH="$TOOLCHAIN_DIR:$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake clean >/dev/null 2>&1 || true
    
    # Retry with single job
    if ! env PATH="$TOOLCHAIN_DIR:$PATH" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" CC="$CC" CXX="$CXX" gmake; then
        log_error "Kernel build failed even with single-threaded mode"
        log_error "This indicates a serious build issue (not just parallelism)"
        log_error "Suggestions:"
        log_error "  - Check available disk space: df -h $BUILD_DIR"
        log_error "  - Check available memory: free -h"
        log_error "  - Verify toolchain: ${CROSS_COMPILE}gcc --version"
        log_error "  - Review patches for compatibility with Linux ${LINUX_VERSION}"
        popd
        exit 1
    fi
    
    log_success "Kernel build succeeded with single-threaded mode (fallback)"
else
    log_success "Kernel build succeeded with $PARALLEL_JOBS parallel job(s)"
fi

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

# ISO Packaging: Stage kernel artifacts for final use
log_info "ISO Packaging: Staging kernel artifacts..."

# Rename kernel image to standard vmlinuz name
log_info "Staging kernel image as vmlinuz..."
if ! cp "$kernel_dir/arch/$KERNEL_ARCH/boot/Image" "$KERNEL_OUTPUT/vmlinuz"; then
    log_error "Failed to stage kernel image as vmlinuz"
    exit 1
fi
log_success "Kernel image staged as: $KERNEL_OUTPUT/vmlinuz"

# Verify vmlinuz was created
if ! [[ -f "$KERNEL_OUTPUT/vmlinuz" ]]; then
    log_error "Kernel image vmlinuz not found after staging"
    exit 1
fi
log_success "✓ vmlinuz verified"

# Copy System.map for debugging kernel panics and address resolution
if [[ -f "$kernel_dir/System.map" ]]; then
    log_info "Staging System.map for debugging..."
    cp "$kernel_dir/System.map" "$KERNEL_OUTPUT/System.map" || {
        log_error "Failed to copy System.map"
        exit 1
    }
    log_success "✓ System.map staged"
else
    log_warning "System.map not found - kernel debugging symbols will be unavailable"
fi

# Verify final ISO packaging structure
log_success "ISO packaging complete. Final artifact structure:"
log_info "Artifacts location: $KERNEL_OUTPUT"
log_info "Kernel image:       vmlinuz"
log_info "Configuration:      config"
if [[ -f "$KERNEL_OUTPUT/System.map" ]]; then
    log_info "Debug symbols:      System.map"
fi
log_info "Modules:            lib/modules/"

# Summary
log_success "Kernel ready for ISO build:"
log_success "  - Kernel image (vmlinuz) available for boot"
log_success "  - Kernel modules available for initramfs"
log_success "  - Configuration available for auditing"
[[ -f "$KERNEL_OUTPUT/System.map" ]] && log_success "  - Debug symbols available for tracing"
