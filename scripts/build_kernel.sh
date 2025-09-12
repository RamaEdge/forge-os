#!/bin/bash
# Build Linux kernel for ForgeOS
# Usage: build_kernel.sh <arch> <build_dir> <artifacts_dir>

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parameters
ARCH="${1:-aarch64}"
BUILD_DIR="${2:-build/kernel}"
ARTIFACTS_DIR="${3:-artifacts}"

# Load toolchain environment
if [[ -f "$PROJECT_ROOT/toolchains/env.musl" ]]; then
    source "$PROJECT_ROOT/toolchains/env.musl"
else
    echo "Error: Toolchain environment not found. Please run 'make toolchain' first."
    exit 1
fi

echo "Building Linux kernel for $ARCH..."
echo "Build directory: $BUILD_DIR"
echo "Artifacts directory: $ARTIFACTS_DIR"
echo "Cross-compile: $CROSS_COMPILE"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$ARTIFACTS_DIR/arch/arm64/boot"

# Build kernel using the kernel Makefile
echo "Building kernel with hardened configuration..."
cd "$PROJECT_ROOT/kernel"
make ARCH="$ARCH" BUILD_DIR="$BUILD_DIR" OUTPUT_DIR="$ARTIFACTS_DIR"

echo "Kernel build completed successfully"
echo "Artifacts placed in: $ARTIFACTS_DIR/arch/arm64/boot/"

# Verify kernel image
if [[ -f "$ARTIFACTS_DIR/arch/arm64/boot/Image" ]]; then
    echo "Kernel image created successfully"
    file "$ARTIFACTS_DIR/arch/arm64/boot/Image"
else
    echo "Error: Kernel image not found"
    exit 1
fi

exit 0
