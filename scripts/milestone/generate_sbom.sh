#!/bin/bash
# ForgeOS SBOM (Software Bill of Materials) Generation Script
# Implements THE-56 (v0.1 Milestone)
# Generates comprehensive SBOM for ForgeOS artifacts

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Output configuration
SBOM_DIR="$PROJECT_ROOT/artifacts/sbom"
SBOM_FORMAT="${SBOM_FORMAT:-json}"  # json or spdx
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

# Create SBOM directory
mkdir -p "$SBOM_DIR"

log_info "Generating ForgeOS v0.1 SBOM..."
log_info "Format: $SBOM_FORMAT"
log_info "Output: $SBOM_DIR"

# Generate SBOM in JSON format
generate_json_sbom() {
    local output_file="$SBOM_DIR/forgeos-v0.1-sbom.json"
    
    log_info "Generating JSON SBOM..."
    
    # Read versions
    . "$PROJECT_ROOT/versions.sh" 2>/dev/null || true
    
    cat > "$output_file" << EOF
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.4",
  "serialNumber": "urn:uuid:$(uuidgen 2>/dev/null || echo '00000000-0000-0000-0000-000000000000')",
  "version": 1,
  "metadata": {
    "timestamp": "$TIMESTAMP",
    "tools": [
      {
        "vendor": "ForgeOS",
        "name": "generate_sbom.sh",
        "version": "1.0.0"
      }
    ],
    "component": {
      "type": "operating-system",
      "name": "ForgeOS",
      "version": "0.1.0",
      "description": "Lightweight Linux distribution forged for the edge",
      "licenses": [
        {
          "license": {
            "id": "GPL-2.0-only"
          }
        }
      ]
    }
  },
  "components": [
    {
      "type": "operating-system",
      "name": "Linux Kernel",
      "version": "${LINUX_VERSION:-6.6.0}",
      "description": "Linux kernel with security hardening",
      "licenses": [{"license": {"id": "GPL-2.0-only"}}],
      "purl": "pkg:github/torvalds/linux@${LINUX_VERSION:-6.6.0}",
      "externalReferences": [
        {
          "type": "website",
          "url": "https://kernel.org"
        }
      ]
    },
    {
      "type": "library",
      "name": "musl",
      "version": "${MUSL_VERSION:-1.2.4}",
      "description": "musl C standard library",
      "licenses": [{"license": {"id": "MIT"}}],
      "purl": "pkg:github/bminor/musl@${MUSL_VERSION:-1.2.4}",
      "externalReferences": [
        {
          "type": "website",
          "url": "https://musl.libc.org"
        }
      ]
    },
    {
      "type": "library",
      "name": "BusyBox",
      "version": "1.36.1",
      "description": "BusyBox userland utilities",
      "licenses": [{"license": {"id": "GPL-2.0-only"}}],
      "purl": "pkg:github/mirror/busybox@1.36.1",
      "externalReferences": [
        {
          "type": "website",
          "url": "https://busybox.net"
        }
      ]
    },
    {
      "type": "library",
      "name": "binutils",
      "version": "${BINUTILS_VERSION:-2.42}",
      "description": "GNU Binary Utilities",
      "licenses": [{"license": {"id": "GPL-3.0-or-later"}}],
      "purl": "pkg:gnu/binutils@${BINUTILS_VERSION:-2.42}"
    },
    {
      "type": "library",
      "name": "gcc",
      "version": "${GCC_VERSION:-13.2.0}",
      "description": "GNU Compiler Collection",
      "licenses": [{"license": {"id": "GPL-3.0-or-later"}}],
      "purl": "pkg:gnu/gcc@${GCC_VERSION:-13.2.0}"
    },
    {
      "type": "application",
      "name": "chrony",
      "version": "4.3",
      "description": "Chrony NTP client/server",
      "licenses": [{"license": {"id": "GPL-2.0-only"}}],
      "purl": "pkg:generic/chrony@4.3"
    },
    {
      "type": "application",
      "name": "dropbear",
      "version": "2022.83",
      "description": "Dropbear SSH server",
      "licenses": [{"license": {"id": "MIT"}}],
      "purl": "pkg:generic/dropbear@2022.83"
    },
    {
      "type": "application",
      "name": "nftables",
      "version": "1.0.7",
      "description": "nftables firewall",
      "licenses": [{"license": {"id": "GPL-2.0-only"}}],
      "purl": "pkg:generic/nftables@1.0.7"
    },
    {
      "type": "application",
      "name": "iproute2",
      "version": "6.1.0",
      "description": "Linux network utilities",
      "licenses": [{"license": {"id": "GPL-2.0-only"}}],
      "purl": "pkg:generic/iproute2@6.1.0"
    }
  ],
  "dependencies": [
    {
      "ref": "pkg:operating-system/forgeos@0.1.0",
      "dependsOn": [
        "pkg:github/torvalds/linux@${LINUX_VERSION:-6.6.0}",
        "pkg:github/bminor/musl@${MUSL_VERSION:-1.2.4}",
        "pkg:github/mirror/busybox@1.36.1"
      ]
    }
  ]
}
EOF
    
    log_success "JSON SBOM generated: $output_file"
}

# Generate SBOM in SPDX format
generate_spdx_sbom() {
    local output_file="$SBOM_DIR/forgeos-v0.1-sbom.spdx"
    
    log_info "Generating SPDX SBOM..."
    
    # Read versions
    . "$PROJECT_ROOT/versions.sh" 2>/dev/null || true
    
    cat > "$output_file" << EOF
SPDXVersion: SPDX-2.3
DataLicense: CC0-1.0
SPDXID: SPDXRef-DOCUMENT
DocumentName: ForgeOS-v0.1
DocumentNamespace: https://forgeos.org/spdxdocs/forgeos-v0.1-$(uuidgen 2>/dev/null || echo '00000000-0000-0000-0000-000000000000')
Creator: Tool: generate_sbom.sh-1.0.0
Creator: Organization: ForgeOS
Created: $TIMESTAMP

# Package: ForgeOS
PackageName: ForgeOS
SPDXID: SPDXRef-Package-ForgeOS
PackageVersion: 0.1.0
PackageSupplier: Organization: ForgeOS
PackageDownloadLocation: https://github.com/forgeos/forgeos
FilesAnalyzed: false
PackageVerificationCode: 0000000000000000000000000000000000000000
PackageLicenseConcluded: GPL-2.0-only
PackageLicenseDeclared: GPL-2.0-only
PackageCopyrightText: Copyright (c) 2025 ForgeOS Contributors
PackageDescription: Lightweight Linux distribution forged for the edge

# Package: Linux Kernel
PackageName: Linux
SPDXID: SPDXRef-Package-Linux
PackageVersion: ${LINUX_VERSION:-6.6.0}
PackageSupplier: Organization: Linux Foundation
PackageDownloadLocation: https://kernel.org
FilesAnalyzed: false
PackageLicenseConcluded: GPL-2.0-only
PackageLicenseDeclared: GPL-2.0-only
PackageCopyrightText: Copyright (c) Linux Kernel Contributors
PackageDescription: Linux kernel with security hardening

# Package: musl
PackageName: musl
SPDXID: SPDXRef-Package-musl
PackageVersion: ${MUSL_VERSION:-1.2.4}
PackageSupplier: Organization: musl Project
PackageDownloadLocation: https://musl.libc.org
FilesAnalyzed: false
PackageLicenseConcluded: MIT
PackageLicenseDeclared: MIT
PackageCopyrightText: Copyright (c) musl contributors
PackageDescription: musl C standard library

# Package: BusyBox
PackageName: BusyBox
SPDXID: SPDXRef-Package-BusyBox
PackageVersion: 1.36.1
PackageSupplier: Organization: BusyBox Project
PackageDownloadLocation: https://busybox.net
FilesAnalyzed: false
PackageLicenseConcluded: GPL-2.0-only
PackageLicenseDeclared: GPL-2.0-only
PackageCopyrightText: Copyright (c) BusyBox contributors
PackageDescription: BusyBox userland utilities

# Relationships
Relationship: SPDXRef-DOCUMENT DESCRIBES SPDXRef-Package-ForgeOS
Relationship: SPDXRef-Package-ForgeOS DEPENDS_ON SPDXRef-Package-Linux
Relationship: SPDXRef-Package-ForgeOS DEPENDS_ON SPDXRef-Package-musl
Relationship: SPDXRef-Package-ForgeOS DEPENDS_ON SPDXRef-Package-BusyBox
EOF
    
    log_success "SPDX SBOM generated: $output_file"
}

# Generate detailed component list
generate_component_list() {
    local output_file="$SBOM_DIR/components.txt"
    
    log_info "Generating component list..."
    
    cat > "$output_file" << EOF
ForgeOS v0.1 Component List
Generated: $TIMESTAMP

═══════════════════════════════════════════════════════════════════

TOOLCHAIN COMPONENTS:

  binutils $(cat "$PROJECT_ROOT/versions.sh" | grep BINUTILS_VERSION= | cut -d'=' -f2 2>/dev/null || echo "2.45")
    - GNU Binary Utilities
    - License: GPL-3.0-or-later
    - URL: https://www.gnu.org/software/binutils/

  gcc $(cat "$PROJECT_ROOT/versions.sh" | grep GCC_VERSION= | cut -d'=' -f2 2>/dev/null || echo "15.2.0")
    - GNU Compiler Collection
    - License: GPL-3.0-or-later
    - URL: https://gcc.gnu.org/

  musl $(cat "$PROJECT_ROOT/versions.sh" | grep MUSL_VERSION= | cut -d'=' -f2 2>/dev/null || echo "1.2.5")
    - musl C standard library
    - License: MIT
    - URL: https://musl.libc.org/

═══════════════════════════════════════════════════════════════════

KERNEL:

  Linux $(cat "$PROJECT_ROOT/versions.sh" | grep LINUX_VERSION= | cut -d'=' -f2 2>/dev/null || echo "6.6.0")
    - Linux kernel with security hardening
    - License: GPL-2.0-only
    - URL: https://kernel.org/
    - Security features:
      * KASLR (Address Space Layout Randomization)
      * Stack Protection (STACKPROTECTOR_STRONG)
      * SECCOMP (System Call Filtering)
      * AppArmor (Mandatory Access Control)
      * Memory hardening

═══════════════════════════════════════════════════════════════════

USERLAND:

  BusyBox 1.36.1
    - Userland utilities
    - License: GPL-2.0-only
    - URL: https://busybox.net/
    - Features: Static build, minimal applets

═══════════════════════════════════════════════════════════════════

NETWORK & SERVICES:

  chrony 4.3
    - NTP client/server
    - License: GPL-2.0-only
    - URL: https://chrony.tuxfamily.org/

  dropbear 2022.83
    - SSH server
    - License: MIT
    - URL: https://matt.ucc.asn.au/dropbear/

  iproute2 6.1.0
    - Network utilities
    - License: GPL-2.0-only
    - URL: https://wiki.linuxfoundation.org/networking/iproute2

  nftables 1.0.7
    - Firewall
    - License: GPL-2.0-only
    - URL: https://netfilter.org/projects/nftables/

═══════════════════════════════════════════════════════════════════

SECURITY COMPONENTS:

  AppArmor
    - Mandatory Access Control
    - Profiles: dropbear, chronyd, ssh, update-agent

  nftables Firewall
    - Default-deny inbound policy
    - Rate limiting
    - DoS protection
    - Port scan detection

  Package Signing
    - minisign/cosign support
    - Signed artifacts and packages

═══════════════════════════════════════════════════════════════════
EOF
    
    log_success "Component list generated: $output_file"
}

# Main
main() {
    cd "$PROJECT_ROOT"
    
    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "  ForgeOS v0.1 SBOM Generation"
    echo "═══════════════════════════════════════════════════"
    echo ""
    
    case "$SBOM_FORMAT" in
        "json")
            generate_json_sbom
            ;;
        "spdx")
            generate_spdx_sbom
            ;;
        "all")
            generate_json_sbom
            generate_spdx_sbom
            ;;
        *)
            log_info "Unknown format, generating all formats"
            generate_json_sbom
            generate_spdx_sbom
            ;;
    esac
    
    # Always generate component list
    generate_component_list
    
    echo ""
    log_success "SBOM generation completed!"
    log_info "SBOM files:"
    ls -lh "$SBOM_DIR"
    echo ""
}

main "$@"

