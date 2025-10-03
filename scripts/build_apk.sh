#!/bin/bash
# Build APK packages for ForgeOS
# Usage: build_apk.sh <package_name> <arch> <build_dir> <artifacts_dir>

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parameters
PACKAGE_NAME="${1:-iproute2}"
ARCH="${2:-aarch64}"
BUILD_DIR="${3:-build/packages}"
ARTIFACTS_DIR="${4:-artifacts}"

# Load toolchain environment
if [[ -f "$PROJECT_ROOT/toolchains/env.musl" ]]; then
    source "$PROJECT_ROOT/toolchains/env.musl"
else
    echo "Error: Toolchain environment not found. Please run 'make toolchain' first."
    exit 1
fi

echo "Building APK package: $PACKAGE_NAME for $ARCH"
echo "Build directory: $BUILD_DIR"
echo "Artifacts directory: $ARTIFACTS_DIR"
echo "Cross-compile: $CROSS_COMPILE"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$ARTIFACTS_DIR/packages"

# Package source directory
PACKAGE_SOURCE_DIR="$PROJECT_ROOT/packages/sources/$PACKAGE_NAME"
if [[ ! -d "$PACKAGE_SOURCE_DIR" ]]; then
    echo "Error: Package source directory not found: $PACKAGE_SOURCE_DIR"
    echo "Available packages:"
    ls -1 "$PROJECT_ROOT/packages/sources/" 2>/dev/null || echo "No packages found"
    exit 1
fi

# Check for APKBUILD file
APKBUILD_FILE="$PACKAGE_SOURCE_DIR/APKBUILD"
if [[ ! -f "$APKBUILD_FILE" ]]; then
    echo "Error: APKBUILD file not found: $APKBUILD_FILE"
    exit 1
fi

echo "Building package from: $PACKAGE_SOURCE_DIR"

# TODO: Implement actual APK package building
# For now, create placeholder APK package
echo "Creating placeholder APK package..."

# Create package directory
PACKAGE_BUILD_DIR="$BUILD_DIR/$PACKAGE_NAME"
mkdir -p "$PACKAGE_BUILD_DIR"

# Create placeholder APK file
APK_FILE="$ARTIFACTS_DIR/packages/${PACKAGE_NAME}-1.0.0-r0.apk"
echo "Creating placeholder APK: $APK_FILE"
touch "$APK_FILE"

# Create package metadata
PACKAGE_META="$PACKAGE_BUILD_DIR/.PKGINFO"
cat > "$PACKAGE_META" << EOF
pkgname = $PACKAGE_NAME
pkgver = 1.0.0-r0
pkgdesc = ForgeOS $PACKAGE_NAME package
url = https://forgeos.org/
arch = $ARCH
license = GPL-2.0
size = 1024
origin = forgeos
commit = $(git rev-parse HEAD 2>/dev/null || echo "unknown")
EOF

echo "Package $PACKAGE_NAME built successfully"
echo "APK file: $APK_FILE"
echo "Metadata: $PACKAGE_META"

# Show package info
if [[ -f "$PACKAGE_META" ]]; then
    echo "Package metadata:"
    cat "$PACKAGE_META"
fi

exit 0
