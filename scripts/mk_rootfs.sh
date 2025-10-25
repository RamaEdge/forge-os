#!/bin/bash
# Create root filesystem for ForgeOS
# Usage: mk_rootfs.sh <profile> <arch> <build_dir> <artifacts_dir>

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

# Parameters
PROFILE="${1:-core-min}"
ARCH="${2:-aarch64}"
BUILD_DIR="${3:-build/rootfs}"
ARTIFACTS_DIR="${4:-artifacts}"

echo "Creating root filesystem for profile $PROFILE on $ARCH..."
echo "Build directory: $BUILD_DIR"
echo "Artifacts directory: $ARTIFACTS_DIR"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$ARTIFACTS_DIR/rootfs"

# Create rootfs skeleton
echo "Creating root filesystem skeleton..."
"$PROJECT_ROOT/userland/rootfs-skeleton.sh" "$ARTIFACTS_DIR/rootfs"

# Copy BusyBox binary
if [[ -f "$ARTIFACTS_DIR/busybox/busybox" ]]; then
    echo "Installing BusyBox..."
    cp "$ARTIFACTS_DIR/busybox/busybox" "$ARTIFACTS_DIR/rootfs/bin/"
    chmod +x "$ARTIFACTS_DIR/rootfs/bin/busybox"
    
    # Create BusyBox applet symlinks
    echo "Creating BusyBox applet symlinks..."
    cd "$ARTIFACTS_DIR/rootfs"
    "$ARTIFACTS_DIR/rootfs/bin/busybox" --install -s
    cd "$PROJECT_ROOT"
else
    echo "Warning: BusyBox binary not found, creating placeholder symlinks"
    ln -sf /bin/busybox "$ARTIFACTS_DIR/rootfs/bin/sh" 2>/dev/null || true
    ln -sf /bin/busybox "$ARTIFACTS_DIR/rootfs/bin/init" 2>/dev/null || true
fi

# Copy overlay-base configuration
echo "Installing base configuration..."
cp -r "$PROJECT_ROOT/userland/overlay-base"/* "$ARTIFACTS_DIR/rootfs/" 2>/dev/null || true

# Set up APK package system
echo "Setting up APK package system..."
mkdir -p "$ARTIFACTS_DIR/rootfs/etc/apk"
mkdir -p "$ARTIFACTS_DIR/rootfs/var/cache/apk"

# Create APK repositories configuration
cat > "$ARTIFACTS_DIR/rootfs/etc/apk/repositories" << EOF
# ForgeOS APK Repositories
# Local repository
file:///usr/share/apk/repo

# Remote repositories (if available)
# https://dl-cdn.alpinelinux.org/alpine/v3.18/main
# https://dl-cdn.alpinelinux.org/alpine/v3.18/community
EOF

# Install APK tools (placeholder)
echo "Installing APK tools..."
mkdir -p "$ARTIFACTS_DIR/rootfs/usr/bin"
mkdir -p "$ARTIFACTS_DIR/rootfs/usr/share/apk/repo"

# Copy repository packages if available
if [[ -d "$PROJECT_ROOT/packages/repo/$ARCH/main" ]]; then
    echo "Installing repository packages..."
    cp -r "$PROJECT_ROOT/packages/repo/$ARCH/main"/* "$ARTIFACTS_DIR/rootfs/usr/share/apk/repo/" 2>/dev/null || true
fi

# Install profile-specific packages
echo "Installing profile-specific packages..."
"$PROJECT_ROOT/scripts/install_profile_packages.sh" "$PROFILE" "$ARCH" "$ARTIFACTS_DIR/rootfs"

# Set proper permissions
echo "Setting permissions..."
chmod 755 "$ARTIFACTS_DIR/rootfs/etc/init.d/rcS" 2>/dev/null || true
chmod 755 "$ARTIFACTS_DIR/rootfs/etc/init.d/rcK" 2>/dev/null || true

echo "Root filesystem creation completed successfully"
echo "Root filesystem created at: $ARTIFACTS_DIR/rootfs/"

# Show rootfs structure
echo "Root filesystem structure:"
find "$ARTIFACTS_DIR/rootfs" -type f | head -20
echo "... (showing first 20 files)"

exit 0
