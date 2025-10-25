#!/bin/bash
# Build BusyBox for ForgeOS using pre-downloaded source
# Usage: build_busybox.sh <arch> <build_dir> <artifacts_dir>

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
    # Convert to absolute path
    TOOLCHAIN_DIR="$(cd "$TOOLCHAIN_DIR" && pwd)"
    export PATH="$TOOLCHAIN_DIR:$PATH"
    log_info "Added toolchain to PATH: $TOOLCHAIN_DIR"
    
    # Verify the cross-compiler exists
    if [[ ! -f "$TOOLCHAIN_DIR/$CROSS_COMPILE"gcc ]]; then
        log_error "Cross-compiler not found: $TOOLCHAIN_DIR/$CROSS_COMPILE"gcc
        log_error "Available files in $TOOLCHAIN_DIR:"
        ls -la "$TOOLCHAIN_DIR" | head -10
        exit 1
    fi
else
    log_error "Toolchain directory not found: $TOOLCHAIN_DIR"
    log_info "Please run 'make toolchain' first"
    exit 1
fi

log_info "Building Forge (BusyBox) for $ARCH"
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

# Check if forge binary already exists
if [[ -f "$BUSYBOX_OUTPUT/forge" ]]; then
    log_success "Forge binary already exists at $BUSYBOX_OUTPUT"
    log_info "Skipping build (use 'make clean-busybox' to rebuild)"
    exit 0
fi

# Clean build directory to prevent conflicts
log_info "Cleaning build directory to prevent conflicts..."
rm -rf "$BUILD_DIR/busybox" "$BUILD_DIR/busybox-${BUSYBOX_VERSION}"

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
    log_info "Using default config (non-interactive)"
    pushd "$busybox_dir"
    # Use defconfig with timeout to handle interactive prompts
    timeout 30 bash -c 'printf "n\nn\nn\nn\nn\nn\nn\nn\nn\nn\n" | PATH="$TOOLCHAIN_DIR:$PATH" gmake defconfig' || true
    
    # Disable problematic console tools that require kernel headers
    log_info "Disabling problematic console tools..."
    sed -i 's/CONFIG_CHVT=y/# CONFIG_CHVT is not set/' .config
    sed -i 's/CONFIG_CLEAR=y/# CONFIG_CLEAR is not set/' .config
    sed -i 's/CONFIG_DEALLOCVT=y/# CONFIG_DEALLOCVT is not set/' .config
    sed -i 's/CONFIG_DUMPKMAP=y/# CONFIG_DUMPKMAP is not set/' .config
    sed -i 's/CONFIG_FGCONSOLE=y/# CONFIG_FGCONSOLE is not set/' .config
    sed -i 's/CONFIG_KBD_MODE=y/# CONFIG_KBD_MODE is not set/' .config
    sed -i 's/CONFIG_LOADFONT=y/# CONFIG_LOADFONT is not set/' .config
    sed -i 's/CONFIG_LOADKMAP=y/# CONFIG_LOADKMAP is not set/' .config
    sed -i 's/CONFIG_OPENVT=y/# CONFIG_OPENVT is not set/' .config
    sed -i 's/CONFIG_RESET=y/# CONFIG_RESET is not set/' .config
    sed -i 's/CONFIG_RESIZE=y/# CONFIG_RESIZE is not set/' .config
    sed -i 's/CONFIG_SETCONSOLE=y/# CONFIG_SETCONSOLE is not set/' .config
    sed -i 's/CONFIG_SETKEYCODES=y/# CONFIG_SETKEYCODES is not set/' .config
    sed -i 's/CONFIG_SETLOGCONS=y/# CONFIG_SETLOGCONS is not set/' .config
    sed -i 's/CONFIG_SHOWKEY=y/# CONFIG_SHOWKEY is not set/' .config
    
    # Set up Linux kernel headers for cross-compilation
    log_info "Setting up Linux kernel headers for cross-compilation..."
    export KERNEL_HEADERS="$ARTIFACTS_DIR/kernel/$ARCH/usr/include"
    if [[ -d "$KERNEL_HEADERS" ]]; then
        export CFLAGS="$CFLAGS -I$KERNEL_HEADERS"
        log_info "Added kernel headers to CFLAGS: $KERNEL_HEADERS"
    else
        log_warning "Kernel headers not found at $KERNEL_HEADERS"
        log_info "BusyBox will use minimal console support"
    fi
    
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
# Set up environment variables for cross-compilation
export PATH="$TOOLCHAIN_DIR:$PATH"
export CROSS_COMPILE="$CROSS_COMPILE"
export CC="$CROSS_COMPILE"gcc
export CXX="$CROSS_COMPILE"g++
export AR="$CROSS_COMPILE"ar
export LD="$CROSS_COMPILE"ld
export STRIP="$CROSS_COMPILE"strip
export RANLIB="$CROSS_COMPILE"ranlib
export NM="$CROSS_COMPILE"nm
export OBJCOPY="$CROSS_COMPILE"objcopy
export OBJDUMP="$CROSS_COMPILE"objdump

# Verify the cross-compiler is available
if ! command -v "$CROSS_COMPILE"gcc >/dev/null 2>&1; then
    log_error "Cross-compiler not found: $CROSS_COMPILE"gcc
    log_error "PATH: $PATH"
    exit 1
fi

# Use timeout to handle any remaining interactive prompts
timeout 300 gmake -j$(nproc 2>/dev/null || echo 4) || {
    log_error "BusyBox build failed or timed out"
    exit 1
}
popd

# Install BusyBox to artifacts directory
log_info "Installing BusyBox to artifacts directory..."
pushd "$busybox_dir"
# Set up environment variables for cross-compilation
export PATH="$TOOLCHAIN_DIR:$PATH"
export CROSS_COMPILE="$CROSS_COMPILE"
export CC="$CROSS_COMPILE"gcc
export CXX="$CROSS_COMPILE"g++
export AR="$CROSS_COMPILE"ar
export LD="$CROSS_COMPILE"ld
export STRIP="$CROSS_COMPILE"strip
export RANLIB="$CROSS_COMPILE"ranlib
export NM="$CROSS_COMPILE"nm
export OBJCOPY="$CROSS_COMPILE"objcopy
export OBJDUMP="$CROSS_COMPILE"objdump
gmake DESTDIR="$BUSYBOX_OUTPUT" install
popd

# Verify and rename BusyBox installation to 'forge'
if [[ -f "$BUSYBOX_OUTPUT/bin/busybox" ]]; then
    # Rename BusyBox binary to 'forge' for ForgeOS identity
    mv "$BUSYBOX_OUTPUT/bin/busybox" "$BUSYBOX_OUTPUT/bin/forge"
    log_success "BusyBox renamed to 'forge' for ForgeOS identity"
    
    # Create convenience symlink
    ln -sf "bin/forge" "$BUSYBOX_OUTPUT/forge"
    log_success "Created convenience symlink: $BUSYBOX_OUTPUT/forge"
else
    log_error "BusyBox binary not found after installation"
    exit 1
fi

# Copy config
if [[ -f "$busybox_dir/.config" ]]; then
    cp "$busybox_dir/.config" "$BUSYBOX_OUTPUT/config"
    log_success "BusyBox config copied to $BUSYBOX_OUTPUT/config"
fi

log_success "Forge build complete: $BUSYBOX_OUTPUT"

# Clean up build directory (keep only artifacts in artifacts/)
log_info "Cleaning up build directory..."
if [[ -d "$BUILD_DIR/busybox" ]]; then
    # Force remove the directory and all contents
    rm -rf "$BUILD_DIR/busybox" 2>/dev/null || true
    log_success "Build directory cleaned up - all outputs moved to artifacts/"
else
    log_info "Build directory already clean"
fi
