#!/bin/bash
# ForgeOS Root Filesystem Skeleton
# Creates the basic directory structure and device nodes

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parameters
ROOTFS_DIR="${1:-$PROJECT_ROOT/artifacts/rootfs}"

echo "Creating ForgeOS root filesystem skeleton..."
echo "Root filesystem directory: $ROOTFS_DIR"

# Create rootfs directory
mkdir -p "$ROOTFS_DIR"

# Create essential directories
echo "Creating directory structure..."
mkdir -p "$ROOTFS_DIR"/{bin,sbin,usr/{bin,sbin,lib,share},etc,var/{log,run,tmp},tmp,proc,sys,dev,run,home,root,mnt,opt}

# Create device nodes
echo "Creating device nodes..."
mkdir -p "$ROOTFS_DIR/dev"

# Essential device nodes
mknod "$ROOTFS_DIR/dev/console" c 5 1 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$ROOTFS_DIR/dev/null" c 1 3 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$ROOTFS_DIR/dev/zero" c 1 5 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$ROOTFS_DIR/dev/random" c 1 8 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$ROOTFS_DIR/dev/urandom" c 1 9 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$ROOTFS_DIR/dev/tty" c 5 0 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$ROOTFS_DIR/dev/ttyAMA0" c 204 64 2>/dev/null || echo "Note: mknod requires root privileges"

# Set permissions
echo "Setting permissions..."
chmod 755 "$ROOTFS_DIR"
chmod 755 "$ROOTFS_DIR"/{bin,sbin,usr,etc,var,tmp,proc,sys,dev,run,home,root,mnt,opt}
chmod 1777 "$ROOTFS_DIR/tmp"
chmod 755 "$ROOTFS_DIR/var/run"
chmod 755 "$ROOTFS_DIR/var/log"

# Create symlinks
echo "Creating symlinks..."
ln -sf /bin/busybox "$ROOTFS_DIR/bin/sh" 2>/dev/null || echo "Note: BusyBox not yet installed"
ln -sf /bin/busybox "$ROOTFS_DIR/bin/init" 2>/dev/null || echo "Note: BusyBox not yet installed"

echo "Root filesystem skeleton created successfully"
echo "Directory structure:"
tree "$ROOTFS_DIR" 2>/dev/null || find "$ROOTFS_DIR" -type d | sort

exit 0
