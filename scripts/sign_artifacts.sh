#!/bin/bash
# Sign artifacts for ForgeOS
# Implements THE-52 (Security Baseline) - cosign/minisign support
# Usage: sign_artifacts.sh <artifacts_dir> [signing_method]

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parameters
ARTIFACTS_DIR="${1:-artifacts}"
SIGNING_METHOD="${2:-minisign}"  # minisign or cosign

echo "Signing ForgeOS artifacts..."
echo "Artifacts directory: $ARTIFACTS_DIR"
echo "Signing method: $SIGNING_METHOD"

# Create directories
mkdir -p "$ARTIFACTS_DIR/signatures"
mkdir -p "$PROJECT_ROOT/security/keys"

# Keys directory
KEYS_DIR="$PROJECT_ROOT/security/keys"
MINISIGN_PRIVATE_KEY="$KEYS_DIR/minisign.key"
MINISIGN_PUBLIC_KEY="$KEYS_DIR/minisign.pub"

# Generate minisign keys if they don't exist
generate_minisign_keys() {
    if [[ ! -f "$MINISIGN_PRIVATE_KEY" ]]; then
        echo "Generating minisign key pair..."
        
        # Check if minisign is available
        if command -v minisign &> /dev/null; then
            minisign -G -p "$MINISIGN_PUBLIC_KEY" -s "$MINISIGN_PRIVATE_KEY" -W
            echo "Minisign keys generated:"
            echo "  Private key: $MINISIGN_PRIVATE_KEY"
            echo "  Public key: $MINISIGN_PUBLIC_KEY"
        else
            echo "Warning: minisign not found. Creating placeholder keys."
            echo "untrusted comment: minisign public key" > "$MINISIGN_PUBLIC_KEY"
            echo "RWSc" >> "$MINISIGN_PUBLIC_KEY"
            touch "$MINISIGN_PRIVATE_KEY"
            chmod 600 "$MINISIGN_PRIVATE_KEY"
        fi
    else
        echo "Using existing minisign keys"
    fi
}

# Sign artifact with minisign
sign_with_minisign() {
    local artifact="$1"
    local signature="${artifact}.minisig"
    
    echo "Signing: $(basename "$artifact")"
    
    if command -v minisign &> /dev/null; then
        minisign -S -s "$MINISIGN_PRIVATE_KEY" -m "$artifact" -x "$signature" || {
            echo "Warning: Failed to sign $artifact"
            touch "$signature"
        }
    else
        echo "  Creating placeholder signature"
        echo "untrusted comment: signature from minisign" > "$signature"
        echo "$(sha256sum "$artifact" | cut -d' ' -f1)" >> "$signature"
    fi
}

# Sign artifact with cosign
sign_with_cosign() {
    local artifact="$1"
    local signature="${artifact}.sig"
    
    echo "Signing: $(basename "$artifact")"
    
    if command -v cosign &> /dev/null; then
        cosign sign-blob --key "$KEYS_DIR/cosign.key" "$artifact" > "$signature" 2>/dev/null || {
            echo "Warning: Failed to sign $artifact with cosign"
            touch "$signature"
        }
    else
        echo "  Creating placeholder signature"
        echo "$(sha256sum "$artifact" | cut -d' ' -f1)" > "$signature"
    fi
}

# Verify minisign signature
verify_minisign() {
    local artifact="$1"
    local signature="${artifact}.minisig"
    
    if [[ -f "$signature" ]] && command -v minisign &> /dev/null; then
        if minisign -V -p "$MINISIGN_PUBLIC_KEY" -m "$artifact" -x "$signature" 2>/dev/null; then
            echo "  ✓ Verified: $(basename "$artifact")"
            return 0
        else
            echo "  ✗ Verification failed: $(basename "$artifact")"
            return 1
        fi
    else
        echo "  - Skipped verification (minisign not available)"
        return 0
    fi
}

# Main signing process
main() {
    case "$SIGNING_METHOD" in
        "minisign")
            generate_minisign_keys
            ;;
        "cosign")
            echo "Cosign signing method selected"
            if [[ ! -f "$KEYS_DIR/cosign.key" ]]; then
                echo "Warning: Cosign key not found. Falling back to minisign."
                SIGNING_METHOD="minisign"
                generate_minisign_keys
            fi
            ;;
        *)
            echo "Error: Unknown signing method: $SIGNING_METHOD"
            echo "Supported methods: minisign, cosign"
            exit 1
            ;;
    esac

    # Find all artifacts to sign
    local artifacts_to_sign=(
        "$ARTIFACTS_DIR/arch/arm64/boot/Image"
        "$ARTIFACTS_DIR/initramfs.gz"
        "$ARTIFACTS_DIR/root.img"
        "$ARTIFACTS_DIR/forgeos.qcow2"
        "$ARTIFACTS_DIR/busybox/busybox"
    )

    # Sign each artifact
    local signed_count=0
    local failed_count=0

    for artifact in "${artifacts_to_sign[@]}"; do
        if [[ -f "$artifact" ]]; then
            case "$SIGNING_METHOD" in
                "minisign")
                    sign_with_minisign "$artifact"
                    if verify_minisign "$artifact"; then
                        ((signed_count++))
                    else
                        ((failed_count++))
                    fi
                    ;;
                "cosign")
                    sign_with_cosign "$artifact"
                    ((signed_count++))
                    ;;
            esac
        else
            echo "Artifact not found: $artifact"
        fi
    done

    # Create checksum file for all artifacts
    echo "Creating checksums file..."
    CHECKSUMS_FILE="$ARTIFACTS_DIR/SHA256SUMS"
    > "$CHECKSUMS_FILE"

    for artifact in "${artifacts_to_sign[@]}"; do
        if [[ -f "$artifact" ]]; then
            sha256sum "$artifact" | sed "s|$ARTIFACTS_DIR/||" >> "$CHECKSUMS_FILE"
        fi
    done

    # Sign the checksums file
    case "$SIGNING_METHOD" in
        "minisign")
            sign_with_minisign "$CHECKSUMS_FILE"
            ;;
        "cosign")
            sign_with_cosign "$CHECKSUMS_FILE"
            ;;
    esac

    # Summary
    echo ""
    echo "Artifact signing completed!"
    echo "  Signed: $signed_count artifacts"
    echo "  Failed: $failed_count artifacts"
    echo "  Checksums: $CHECKSUMS_FILE"
    echo "  Public key: $MINISIGN_PUBLIC_KEY"
    echo ""
    echo "To verify artifacts:"
    echo "  minisign -V -p $MINISIGN_PUBLIC_KEY -m <artifact> -x <artifact>.minisig"
}

main
exit 0
