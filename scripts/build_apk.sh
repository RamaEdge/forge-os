#!/bin/bash
# Build APK packages for ForgeOS using pre-downloaded sources
# Usage: build_apk.sh <package_name> <arch> <build_dir> <artifacts_dir>

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load centralized versions
source "$PROJECT_ROOT/scripts/versions.sh"

# Parameters
PACKAGE_NAME="${1:-iproute2}"
ARCH="${2:-aarch64}"
BUILD_DIR="${3:-build/packages}"
ARTIFACTS_DIR="${4:-artifacts}"

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
PACKAGE_OUTPUT="$ARTIFACTS_DIR/packages/$ARCH"

# Cross-compilation settings
if [[ "$ARCH" == "aarch64" ]]; then
    CROSS_COMPILE="aarch64-linux-musl-"
else
    CROSS_COMPILE="${ARCH}-linux-musl-"
fi

log_info "Building APK package: $PACKAGE_NAME for $ARCH"
log_info "Build directory: $BUILD_DIR"
log_info "Output directory: $PACKAGE_OUTPUT"
log_info "Cross-compile: $CROSS_COMPILE"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$PACKAGE_OUTPUT"

# Package source directory
PACKAGE_SOURCE_DIR="$PROJECT_ROOT/packages/sources/$PACKAGE_NAME"
if [[ ! -d "$PACKAGE_SOURCE_DIR" ]]; then
    log_error "Package source directory not found: $PACKAGE_SOURCE_DIR"
    log_info "Available packages:"
    ls -1 "$PROJECT_ROOT/packages/sources/" 2>/dev/null || echo "No packages found"
    exit 1
fi

# Check for APKBUILD file
APKBUILD_FILE="$PACKAGE_SOURCE_DIR/APKBUILD"
if [[ ! -f "$APKBUILD_FILE" ]]; then
    log_error "APKBUILD file not found: $APKBUILD_FILE"
    exit 1
fi

log_info "Building package from: $PACKAGE_SOURCE_DIR"

# Get package version from versions.sh
PACKAGE_VERSION_VAR="${PACKAGE_NAME^^}_VERSION"
PACKAGE_VERSION="${!PACKAGE_VERSION_VAR:-1.0.0}"

# Check if source tarball exists
PACKAGE_TARBALL=""
case "$PACKAGE_NAME" in
    "iproute2")
        PACKAGE_TARBALL="$DOWNLOADS_DIR/iproute2-${IPROUTE2_VERSION}.tar.xz"
        ;;
    "chrony")
        PACKAGE_TARBALL="$DOWNLOADS_DIR/chrony-${CHRONY_VERSION}.tar.gz"
        ;;
    "dropbear")
        PACKAGE_TARBALL="$DOWNLOADS_DIR/dropbear-${DROPBEAR_VERSION}.tar.bz2"
        ;;
    "nftables")
        PACKAGE_TARBALL="$DOWNLOADS_DIR/nftables-${NFTABLES_VERSION}.tar.xz"
        ;;
    *)
        log_warning "Unknown package: $PACKAGE_NAME, using placeholder build"
        PACKAGE_TARBALL=""
        ;;
esac

# Create package directory
PACKAGE_BUILD_DIR="$BUILD_DIR/$PACKAGE_NAME"
mkdir -p "$PACKAGE_BUILD_DIR"

if [[ -n "$PACKAGE_TARBALL" && -f "$PACKAGE_TARBALL" ]]; then
    log_info "Using pre-downloaded source: $PACKAGE_TARBALL"
    
    # Extract source
    log_info "Extracting package source..."
    cd "$PACKAGE_BUILD_DIR"
    tar -xf "$PACKAGE_TARBALL"
    
    # Find extracted directory
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "${PACKAGE_NAME}-*" | head -1)
    if [[ -n "$EXTRACTED_DIR" ]]; then
        cd "$EXTRACTED_DIR"
        log_info "Building in directory: $EXTRACTED_DIR"
        
        # Set up environment
        export ARCH="$ARCH"
        export CROSS_COMPILE="$CROSS_COMPILE"
        export CC="${CROSS_COMPILE}gcc"
        export CXX="${CROSS_COMPILE}g++"
        export AR="${CROSS_COMPILE}ar"
        export STRIP="${CROSS_COMPILE}strip"
        
        # Configure and build
        log_info "Configuring package..."
        if [[ -f "configure" ]]; then
            ./configure --host="$ARCH-linux-musl" --prefix="/usr"
        elif [[ -f "configure.ac" ]]; then
            autoreconf -fiv
            ./configure --host="$ARCH-linux-musl" --prefix="/usr"
        fi
        
        log_info "Building package..."
        gmake -j$(nproc 2>/dev/null || echo 4)
        
        log_info "Installing package..."
        gmake DESTDIR="$PACKAGE_BUILD_DIR/install" install
        
        log_success "Package built from source successfully"
    else
        log_error "Could not find extracted directory for $PACKAGE_NAME"
        exit 1
    fi
else
    log_warning "Source tarball not found, creating placeholder APK package"
fi

# Create APK package
log_info "Creating APK package..."

# Create package metadata
PACKAGE_META="$PACKAGE_BUILD_DIR/.PKGINFO"
cat > "$PACKAGE_META" << EOF
pkgname = $PACKAGE_NAME
pkgver = $PACKAGE_VERSION-r0
pkgdesc = ForgeOS $PACKAGE_NAME package
url = https://forgeos.org/
arch = $ARCH
license = GPL-2.0
size = $(du -sb "$PACKAGE_BUILD_DIR" 2>/dev/null | cut -f1 || echo "1024")
origin = forgeos
commit = $(git rev-parse HEAD 2>/dev/null || echo "unknown")
EOF

# Create APK file (placeholder for now)
APK_FILE="$PACKAGE_OUTPUT/${PACKAGE_NAME}-${PACKAGE_VERSION}-r0.apk"
log_info "Creating APK: $APK_FILE"

# For now, create a tar.gz as APK placeholder
cd "$PACKAGE_BUILD_DIR"
tar -czf "$APK_FILE" .PKGINFO install/ 2>/dev/null || tar -czf "$APK_FILE" .PKGINFO

log_success "Package $PACKAGE_NAME built successfully"
log_info "APK file: $APK_FILE"
log_info "Metadata: $PACKAGE_META"

# Show package info
if [[ -f "$PACKAGE_META" ]]; then
    log_info "Package metadata:"
    cat "$PACKAGE_META"
fi
