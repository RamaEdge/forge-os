#!/bin/bash
# Build BusyBox for ForgeOS
# Usage: build_busybox.sh <arch> <build_dir> <artifacts_dir>

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parameters
ARCH="${1:-aarch64}"
BUILD_DIR="${2:-build/busybox}"
ARTIFACTS_DIR="${3:-artifacts}"

# Load toolchain environment
if [[ -f "$PROJECT_ROOT/toolchains/env.musl" ]]; then
    source "$PROJECT_ROOT/toolchains/env.musl"
else
    echo "Error: Toolchain environment not found. Please run 'make toolchain' first."
    exit 1
fi

echo "Building BusyBox for $ARCH..."
echo "Build directory: $BUILD_DIR"
echo "Artifacts directory: $ARTIFACTS_DIR"
echo "Cross-compile: $CROSS_COMPILE"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$ARTIFACTS_DIR/busybox"

# Build BusyBox using the userland Makefile
echo "Building BusyBox with static configuration..."
cd "$PROJECT_ROOT/userland/busybox"
make ARCH="$ARCH" BUILD_DIR="$BUILD_DIR" OUTPUT_DIR="$ARTIFACTS_DIR"

echo "BusyBox build completed successfully"
echo "Artifacts placed in: $ARTIFACTS_DIR/busybox/"

# Verify BusyBox binary
if [[ -f "$ARTIFACTS_DIR/busybox/busybox" ]]; then
    echo "BusyBox binary created successfully"
    file "$ARTIFACTS_DIR/busybox/busybox"
else
    echo "Error: BusyBox binary not found"
    exit 1
fi

exit 0
