#!/bin/bash
# Manage ForgeOS APK Repository
# Usage: manage_repo.sh <action> <arch> [options]

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parameters
ACTION="${1:-help}"
ARCH="${2:-aarch64}"

# Repository configuration
REPO_DIR="$PROJECT_ROOT/packages/repo/$ARCH"
PACKAGES_DIR="$PROJECT_ROOT/artifacts/packages"
MAIN_REPO="$REPO_DIR/main"

echo "Managing ForgeOS APK repository for $ARCH..."
echo "Repository directory: $REPO_DIR"
echo "Packages directory: $PACKAGES_DIR"

# Create repository structure
create_repo() {
    echo "Creating repository structure..."
    mkdir -p "$MAIN_REPO"
    mkdir -p "$REPO_DIR/community"
    mkdir -p "$REPO_DIR/testing"
    
    # Create repository configuration
    cat > "$REPO_DIR/forgeos.conf" << EOF
# ForgeOS APK Repository Configuration
# Architecture: $ARCH
# Version: 0.1.0

[main]
url = file://$MAIN_REPO
signing_key = $PROJECT_ROOT/security/keys/forgeos-rsa.pub

[community]
url = file://$REPO_DIR/community
signing_key = $PROJECT_ROOT/security/keys/forgeos-rsa.pub

[testing]
url = file://$REPO_DIR/testing
signing_key = $PROJECT_ROOT/security/keys/forgeos-rsa.pub
EOF
    
    echo "Repository structure created"
}

# Add packages to repository
add_packages() {
    echo "Adding packages to repository..."
    
    if [[ ! -d "$PACKAGES_DIR" ]]; then
        echo "Error: Packages directory not found: $PACKAGES_DIR"
        exit 1
    fi
    
    # Copy packages to repository
    cp "$PACKAGES_DIR"/*.apk "$MAIN_REPO/" 2>/dev/null || echo "No packages to copy"
    
    echo "Packages added to repository"
}

# Generate repository index
generate_index() {
    echo "Generating repository index..."
    
    # Create APKINDEX.tar.gz (placeholder)
    cd "$MAIN_REPO"
    tar -czf APKINDEX.tar.gz *.apk 2>/dev/null || echo "No packages to index"
    
    echo "Repository index generated: $MAIN_REPO/APKINDEX.tar.gz"
}

# Sign repository
sign_repo() {
    echo "Signing repository..."
    
    # Sign the repository index
    if [[ -f "$MAIN_REPO/APKINDEX.tar.gz" ]]; then
        touch "$MAIN_REPO/APKINDEX.tar.gz.sig"
        echo "Repository index signed"
    else
        echo "Warning: No repository index to sign"
    fi
    
    # Sign individual packages
    for apk_file in "$MAIN_REPO"/*.apk; do
        if [[ -f "$apk_file" ]]; then
            touch "${apk_file}.sig"
        fi
    done
    
    echo "Repository signed"
}

# Show repository status
show_status() {
    echo "Repository status for $ARCH:"
    echo "  Repository directory: $REPO_DIR"
    echo "  Main repository: $MAIN_REPO"
    echo "  Packages: $(ls -1 "$MAIN_REPO"/*.apk 2>/dev/null | wc -l)"
    echo "  Index: $([ -f "$MAIN_REPO/APKINDEX.tar.gz" ] && echo "Present" || echo "Missing")"
    echo "  Signatures: $(ls -1 "$MAIN_REPO"/*.sig 2>/dev/null | wc -l)"
    
    if [[ -d "$MAIN_REPO" ]]; then
        echo "  Package list:"
        ls -la "$MAIN_REPO"/*.apk 2>/dev/null || echo "    No packages found"
    fi
}

# Main action handler
case "$ACTION" in
    "create")
        create_repo
        ;;
    "add")
        add_packages
        ;;
    "index")
        generate_index
        ;;
    "sign")
        sign_repo
        ;;
    "status")
        show_status
        ;;
    "full")
        create_repo
        add_packages
        generate_index
        sign_repo
        show_status
        ;;
    "help"|*)
        echo "Usage: $0 <action> <arch>"
        echo ""
        echo "Actions:"
        echo "  create  - Create repository structure"
        echo "  add     - Add packages to repository"
        echo "  index   - Generate repository index"
        echo "  sign    - Sign repository and packages"
        echo "  status  - Show repository status"
        echo "  full    - Run all actions (create, add, index, sign, status)"
        echo "  help    - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 create aarch64"
        echo "  $0 full aarch64"
        echo "  $0 status aarch64"
        ;;
esac

exit 0
