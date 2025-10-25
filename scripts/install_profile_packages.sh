#!/bin/bash
# Install profile-specific packages for ForgeOS
# Usage: install_profile_packages.sh <profile> <arch> <rootfs_dir>

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
ROOTFS_DIR="${3:-$PROJECT_ROOT/artifacts/rootfs}"

echo "Installing packages for profile: $PROFILE on $ARCH"
echo "Root filesystem directory: $ROOTFS_DIR"

# Validate profile exists
PROFILE_DIR="$PROJECT_ROOT/profiles/$PROFILE"
if [[ ! -d "$PROFILE_DIR" ]]; then
    echo "Error: Profile '$PROFILE' not found"
    exit 1
fi

# Validate rootfs directory exists
if [[ ! -d "$ROOTFS_DIR" ]]; then
    echo "Error: Root filesystem directory '$ROOTFS_DIR' not found"
    exit 1
fi

# Process package list
PACKAGES_FILE="$PROFILE_DIR/packages.txt"
if [[ -f "$PACKAGES_FILE" ]]; then
    echo "Processing package list: $PACKAGES_FILE"
    
    # Read package list and install packages
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        
        # Extract package name (remove version and comments)
        package_name=$(echo "$line" | sed 's/[[:space:]]*#.*$//' | sed 's/[[:space:]]*$//')
        
        if [[ -n "$package_name" ]]; then
            echo "Installing package: $package_name"
            install_package "$package_name" "$ARCH" "$ROOTFS_DIR"
        fi
    done < "$PACKAGES_FILE"
else
    echo "Warning: No packages.txt found for profile $PROFILE"
fi

# Function to install a package
install_package() {
    local package_name="$1"
    local arch="$2"
    local rootfs_dir="$3"
    
    echo "Installing package: $package_name"
    
    # Check if package exists in repository
    local repo_dir="$PROJECT_ROOT/packages/repo/$arch/main"
    local package_file="$repo_dir/${package_name}-*.apk"
    
    if ls $package_file 1> /dev/null 2>&1; then
        echo "Found package: $package_file"
        # TODO: Implement actual APK installation
        # For now, create placeholder installation
        echo "Package $package_name installed (placeholder)"
    else
        echo "Warning: Package $package_name not found in repository"
        echo "Available packages:"
        ls -1 "$repo_dir"/*.apk 2>/dev/null || echo "No packages available"
    fi
}

# Install base packages for all profiles
echo "Installing base packages..."

# Create package installation directory
mkdir -p "$ROOTFS_DIR/usr/share/apk/repo"

# Copy base packages if available
BASE_PACKAGES_DIR="$PROJECT_ROOT/artifacts/packages"
if [[ -d "$BASE_PACKAGES_DIR" ]]; then
    echo "Installing base packages from: $BASE_PACKAGES_DIR"
    cp "$BASE_PACKAGES_DIR"/*.apk "$ROOTFS_DIR/usr/share/apk/repo/" 2>/dev/null || echo "No base packages to install"
fi

# Create package installation log
echo "Package installation completed for profile: $PROFILE" > "$ROOTFS_DIR/var/log/package-install.log"
echo "Installed packages:" >> "$ROOTFS_DIR/var/log/package-install.log"
ls -1 "$ROOTFS_DIR/usr/share/apk/repo"/*.apk 2>/dev/null >> "$ROOTFS_DIR/var/log/package-install.log" || echo "No packages installed" >> "$ROOTFS_DIR/var/log/package-install.log"

echo "Profile package installation completed successfully"
echo "Installation log: $ROOTFS_DIR/var/log/package-install.log"

exit 0
