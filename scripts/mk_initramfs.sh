#!/bin/bash
# Create initramfs for ForgeOS
# Usage: mk_initramfs.sh <profile> <arch> <build_dir> <artifacts_dir>

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parameters
PROFILE="${1:-core-min}"
ARCH="${2:-aarch64}"
BUILD_DIR="${3:-build/initramfs}"
ARTIFACTS_DIR="${4:-artifacts}"

echo "Creating initramfs for profile $PROFILE on $ARCH..."
echo "Build directory: $BUILD_DIR"
echo "Artifacts directory: $ARTIFACTS_DIR"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$ARTIFACTS_DIR"

# TODO: Implement initramfs creation logic
# This is a placeholder script for THE-51 (Root Filesystem & Images)

echo "Initramfs creation completed (placeholder)"
echo "Artifacts will be placed in: $ARTIFACTS_DIR/"

# Placeholder: Create dummy initramfs for testing
touch "$ARTIFACTS_DIR/initramfs.gz"
echo "Created placeholder initramfs.gz"

exit 0
