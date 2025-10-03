#!/bin/bash
# Apply ForgeOS Profile to Root Filesystem
# Usage: apply_profile.sh <profile> <rootfs_dir>

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parameters
PROFILE="${1:-core-min}"
ROOTFS_DIR="${2:-$PROJECT_ROOT/artifacts/rootfs}"

echo "Applying ForgeOS profile: $PROFILE"
echo "Root filesystem directory: $ROOTFS_DIR"

# Validate profile exists
PROFILE_DIR="$PROJECT_ROOT/profiles/$PROFILE"
if [[ ! -d "$PROFILE_DIR" ]]; then
    echo "Error: Profile '$PROFILE' not found in $PROJECT_ROOT/profiles/"
    echo "Available profiles:"
    ls -1 "$PROJECT_ROOT/profiles/" 2>/dev/null || echo "No profiles found"
    exit 1
fi

# Validate rootfs directory exists
if [[ ! -d "$ROOTFS_DIR" ]]; then
    echo "Error: Root filesystem directory '$ROOTFS_DIR' not found"
    exit 1
fi

# Apply profile overlay
OVERLAY_DIR="$PROFILE_DIR/overlay"
if [[ -d "$OVERLAY_DIR" ]]; then
    echo "Applying profile overlay..."
    cp -r "$OVERLAY_DIR"/* "$ROOTFS_DIR/" 2>/dev/null || true
    
    # Set proper permissions on init scripts
    if [[ -f "$ROOTFS_DIR/etc/init.d/rcS" ]]; then
        chmod +x "$ROOTFS_DIR/etc/init.d/rcS"
    fi
    if [[ -f "$ROOTFS_DIR/etc/init.d/rcK" ]]; then
        chmod +x "$ROOTFS_DIR/etc/init.d/rcK"
    fi
    
    echo "Profile overlay applied successfully"
else
    echo "Warning: No overlay directory found for profile $PROFILE"
fi

# Process package list (placeholder for future package system)
PACKAGES_FILE="$PROFILE_DIR/packages.txt"
if [[ -f "$PACKAGES_FILE" ]]; then
    echo "Processing package list..."
    echo "Package list found: $PACKAGES_FILE"
    echo "Note: Package installation will be implemented with package system"
    # TODO: Implement package installation when package system is ready
else
    echo "Warning: No packages.txt found for profile $PROFILE"
fi

# Create profile marker
echo "Creating profile marker..."
echo "$PROFILE" > "$ROOTFS_DIR/etc/forgeos-profile"
echo "ForgeOS Profile: $PROFILE" >> "$ROOTFS_DIR/etc/motd"

# Update fstab for profile-specific mounts
echo "Updating fstab for profile $PROFILE..."
case "$PROFILE" in
    "core-min")
        # core-min: minimal mounts, no network-specific mounts
        echo "# core-min profile: minimal file system mounts" >> "$ROOTFS_DIR/etc/fstab"
        ;;
    "core-net")
        # core-net: add network-specific mounts if needed
        echo "# core-net profile: network-enabled file system mounts" >> "$ROOTFS_DIR/etc/fstab"
        ;;
    *)
        echo "# $PROFILE profile: custom file system mounts" >> "$ROOTFS_DIR/etc/fstab"
        ;;
esac

echo "Profile $PROFILE applied successfully to $ROOTFS_DIR"
echo "Profile marker created: $ROOTFS_DIR/etc/forgeos-profile"

# Show applied profile structure
echo "Applied profile structure:"
find "$ROOTFS_DIR/etc" -name "*.conf" -o -name "rcS" -o -name "rcK" -o -name "inittab" -o -name "motd" 2>/dev/null | sort

exit 0
