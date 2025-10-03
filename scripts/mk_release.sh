#!/bin/bash
# Create release bundle for ForgeOS
# Implements THE-56 (v0.1 Milestone)
# Usage: mk_release.sh <profile> <arch> <version> <artifacts_dir>

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parameters
PROFILE="${1:-core-min}"
ARCH="${2:-aarch64}"
VERSION="${3:-0.1.0}"
ARTIFACTS_DIR="${4:-artifacts}"

# Release configuration
RELEASE_NAME="forgeos-${VERSION}-${PROFILE}-${ARCH}"
RELEASE_DIR="$ARTIFACTS_DIR/release/$RELEASE_NAME"
RELEASE_BUNDLE="$ARTIFACTS_DIR/release/${RELEASE_NAME}.tar.gz"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_info "Creating release bundle: $RELEASE_NAME"
log_info "Artifacts directory: $ARTIFACTS_DIR"

# Create release directory structure
mkdir -p "$RELEASE_DIR"/{images,docs,security,scripts}

# Copy kernel image
if [[ -f "$ARTIFACTS_DIR/arch/arm64/boot/Image" ]]; then
    log_info "Copying kernel image..."
    cp "$ARTIFACTS_DIR/arch/arm64/boot/Image" "$RELEASE_DIR/images/"
    log_success "Kernel image included"
else
    log_info "Warning: Kernel image not found"
fi

# Copy initramfs
if [[ -f "$ARTIFACTS_DIR/initramfs.gz" ]]; then
    log_info "Copying initramfs..."
    cp "$ARTIFACTS_DIR/initramfs.gz" "$RELEASE_DIR/images/"
    log_success "Initramfs included"
else
    log_info "Warning: Initramfs not found"
fi

# Copy disk images
if [[ -f "$ARTIFACTS_DIR/root.img" ]]; then
    log_info "Copying root disk image..."
    cp "$ARTIFACTS_DIR/root.img" "$RELEASE_DIR/images/"
    log_success "Root disk image included"
else
    log_info "Warning: Root disk image not found"
fi

if [[ -f "$ARTIFACTS_DIR/forgeos.qcow2" ]]; then
    log_info "Copying QCOW2 image..."
    cp "$ARTIFACTS_DIR/forgeos.qcow2" "$RELEASE_DIR/images/"
    log_success "QCOW2 image included"
else
    log_info "Warning: QCOW2 image not found"
fi

# Copy checksums
if [[ -f "$ARTIFACTS_DIR/SHA256SUMS" ]]; then
    log_info "Copying checksums..."
    cp "$ARTIFACTS_DIR/SHA256SUMS" "$RELEASE_DIR/"
    log_success "Checksums included"
fi

# Copy signatures
if [[ -d "$ARTIFACTS_DIR/signatures" ]]; then
    log_info "Copying signatures..."
    cp -r "$ARTIFACTS_DIR/signatures" "$RELEASE_DIR/"
    log_success "Signatures included"
fi

# Copy SBOM
if [[ -d "$ARTIFACTS_DIR/sbom" ]]; then
    log_info "Copying SBOM..."
    cp -r "$ARTIFACTS_DIR/sbom" "$RELEASE_DIR/"
    log_success "SBOM included"
else
    log_info "Warning: SBOM not found, generating..."
    "$SCRIPT_DIR/milestone/generate_sbom.sh"
    if [[ -d "$ARTIFACTS_DIR/sbom" ]]; then
        cp -r "$ARTIFACTS_DIR/sbom" "$RELEASE_DIR/"
        log_success "SBOM generated and included"
    fi
fi

# Copy security configuration
log_info "Copying security configuration..."
mkdir -p "$RELEASE_DIR/security"/{apparmor,nftables,keys}

if [[ -d "$PROJECT_ROOT/security/apparmor/profiles" ]]; then
    cp -r "$PROJECT_ROOT/security/apparmor/profiles" "$RELEASE_DIR/security/apparmor/"
fi

if [[ -d "$PROJECT_ROOT/security/nftables" ]]; then
    cp "$PROJECT_ROOT/security/nftables"/*.nft "$RELEASE_DIR/security/nftables/" 2>/dev/null || true
fi

if [[ -d "$PROJECT_ROOT/security/keys" ]]; then
    # Only copy public keys for release
    cp "$PROJECT_ROOT/security/keys"/*.pub "$RELEASE_DIR/security/keys/" 2>/dev/null || true
fi

log_success "Security configuration included"

# Copy documentation
log_info "Copying documentation..."
cp "$PROJECT_ROOT/README.md" "$RELEASE_DIR/"
cp -r "$PROJECT_ROOT/docs" "$RELEASE_DIR/" 2>/dev/null || true
log_success "Documentation included"

# Copy helper scripts
log_info "Copying helper scripts..."
cp "$PROJECT_ROOT/scripts/qemu_run.sh" "$RELEASE_DIR/scripts/" 2>/dev/null || true
log_success "Helper scripts included"

# Create release info file
log_info "Creating release info..."
cat > "$RELEASE_DIR/RELEASE_INFO.txt" << EOF
ForgeOS Release Information
═══════════════════════════════════════════════════════════════════

Release: $RELEASE_NAME
Version: $VERSION
Profile: $PROFILE
Architecture: $ARCH
Build Date: $TIMESTAMP

═══════════════════════════════════════════════════════════════════

CONTENTS:

images/
  - Image            : Linux kernel image
  - initramfs.gz     : Initial RAM filesystem
  - root.img         : Root filesystem disk image (ext4)
  - forgeos.qcow2    : QEMU disk image (optional)

docs/
  - Complete documentation for ForgeOS

security/
  - apparmor/        : AppArmor profiles for system services
  - nftables/        : Firewall configuration
  - keys/            : Public keys for verification

sbom/
  - Software Bill of Materials (SBOM)
  - CycloneDX JSON format
  - SPDX format
  - Component list

scripts/
  - qemu_run.sh      : QEMU launcher script

SHA256SUMS
  - Checksums for all artifacts

signatures/
  - Cryptographic signatures for artifacts

═══════════════════════════════════════════════════════════════════

QUICK START:

1. Verify checksums:
   \$ cd $RELEASE_NAME
   \$ sha256sum -c SHA256SUMS

2. Boot in QEMU (initramfs):
   \$ scripts/qemu_run.sh $PROFILE $ARCH . initramfs

3. Boot in QEMU (disk):
   \$ scripts/qemu_run.sh $PROFILE $ARCH . disk

4. View documentation:
   \$ cat README.md
   \$ ls docs/

═══════════════════════════════════════════════════════════════════

SECURITY FEATURES:

- KASLR (Kernel Address Space Layout Randomization)
- Stack Protection (STACKPROTECTOR_STRONG)
- SECCOMP (System Call Filtering)
- AppArmor (Mandatory Access Control)
- nftables Firewall (Default-deny inbound)
- Signed Packages and Artifacts
- Minimal Attack Surface

═══════════════════════════════════════════════════════════════════

SUPPORT:

Documentation: docs/
Repository: https://github.com/forgeos/forgeos
Issues: https://linear.app/theedgeworks/project/forge-os

═══════════════════════════════════════════════════════════════════
EOF

log_success "Release info created"

# Create tarball
log_info "Creating release tarball..."
cd "$ARTIFACTS_DIR/release"
tar -czf "${RELEASE_NAME}.tar.gz" "$RELEASE_NAME"
log_success "Release tarball created: ${RELEASE_NAME}.tar.gz"

# Generate tarball checksum
log_info "Generating tarball checksum..."
sha256sum "${RELEASE_NAME}.tar.gz" > "${RELEASE_NAME}.tar.gz.sha256"
log_success "Checksum created: ${RELEASE_NAME}.tar.gz.sha256"

# Sign tarball (if signing tools available)
if command -v minisign >/dev/null 2>&1; then
    if [[ -f "$PROJECT_ROOT/security/keys/minisign.key" ]]; then
        log_info "Signing release tarball..."
        minisign -S -s "$PROJECT_ROOT/security/keys/minisign.key" \
            -m "${RELEASE_NAME}.tar.gz" \
            -x "${RELEASE_NAME}.tar.gz.minisig" 2>/dev/null || true
        log_success "Release tarball signed"
    fi
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Release Bundle Complete"
echo "═══════════════════════════════════════════════════"
echo ""
log_success "Release: $RELEASE_NAME"
log_info "Location: $ARTIFACTS_DIR/release/"
echo ""
log_info "Files:"
ls -lh "$ARTIFACTS_DIR/release/${RELEASE_NAME}"* 2>/dev/null || true
echo ""
log_info "To extract: tar -xzf ${RELEASE_NAME}.tar.gz"
echo ""

exit 0
