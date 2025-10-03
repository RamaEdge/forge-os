#!/bin/bash
# Launch QEMU for ForgeOS testing
# Implements THE-51 (Root Filesystem & Images)
# Usage: qemu_run.sh <profile> <arch> <artifacts_dir> [boot_mode]

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parameters
PROFILE="${1:-core-min}"
ARCH="${2:-aarch64}"
ARTIFACTS_DIR="${3:-artifacts}"
BOOT_MODE="${4:-initramfs}"  # initramfs or disk

# QEMU configuration
QEMU_ARCH="aarch64"
QEMU_MACHINE="virt"
QEMU_CPU="max"
QEMU_ACCEL="hvf"
QEMU_MEMORY="1024"
QEMU_CONSOLE="ttyAMA0"

echo "Launching QEMU for profile $PROFILE on $ARCH..."
echo "Artifacts directory: $ARTIFACTS_DIR"
echo "Boot mode: $BOOT_MODE"

# Check if QEMU is available
if ! command -v qemu-system-aarch64 &> /dev/null; then
    echo "Error: qemu-system-aarch64 not found. Please install QEMU."
    exit 1
fi

# Check if kernel exists
if [[ ! -f "$ARTIFACTS_DIR/arch/arm64/boot/Image" ]]; then
    echo "Error: Kernel image not found at $ARTIFACTS_DIR/arch/arm64/boot/Image"
    echo "Please run 'make kernel' first."
    exit 1
fi

# Check boot mode and required artifacts
case "$BOOT_MODE" in
    "initramfs")
        if [[ ! -f "$ARTIFACTS_DIR/initramfs.gz" ]]; then
            echo "Error: Initramfs not found at $ARTIFACTS_DIR/initramfs.gz"
            echo "Please run 'make initramfs' first."
            exit 1
        fi
        echo "Boot mode: Initramfs only"
        ;;
    "disk")
        if [[ ! -f "$ARTIFACTS_DIR/root.img" ]]; then
            echo "Error: Root disk image not found at $ARTIFACTS_DIR/root.img"
            echo "Please run 'make image' first."
            exit 1
        fi
        echo "Boot mode: Disk root"
        ;;
    "both")
        if [[ ! -f "$ARTIFACTS_DIR/initramfs.gz" ]]; then
            echo "Error: Initramfs not found at $ARTIFACTS_DIR/initramfs.gz"
            echo "Please run 'make initramfs' first."
            exit 1
        fi
        if [[ ! -f "$ARTIFACTS_DIR/root.img" ]]; then
            echo "Error: Root disk image not found at $ARTIFACTS_DIR/root.img"
            echo "Please run 'make image' first."
            exit 1
        fi
        echo "Boot mode: Both initramfs and disk (pivot root)"
        ;;
    *)
        echo "Error: Invalid boot mode '$BOOT_MODE'"
        echo "Valid modes: initramfs, disk, both"
        exit 1
        ;;
esac

# Build QEMU command
QEMU_CMD="qemu-system-aarch64"
QEMU_CMD="$QEMU_CMD -M $QEMU_MACHINE"
QEMU_CMD="$QEMU_CMD -cpu $QEMU_CPU"
QEMU_CMD="$QEMU_CMD -accel $QEMU_ACCEL"
QEMU_CMD="$QEMU_CMD -m $QEMU_MEMORY"
QEMU_CMD="$QEMU_CMD -nographic"
QEMU_CMD="$QEMU_CMD -serial mon:stdio"

# Add kernel
QEMU_CMD="$QEMU_CMD -kernel $ARTIFACTS_DIR/arch/arm64/boot/Image"

# Add boot configuration based on mode
case "$BOOT_MODE" in
    "initramfs")
        QEMU_CMD="$QEMU_CMD -initrd $ARTIFACTS_DIR/initramfs.gz"
        QEMU_CMD="$QEMU_CMD -append \"console=$QEMU_CONSOLE\""
        ;;
    "disk")
        QEMU_CMD="$QEMU_CMD -drive file=$ARTIFACTS_DIR/root.img,format=raw,if=virtio"
        QEMU_CMD="$QEMU_CMD -append \"console=$QEMU_CONSOLE root=/dev/vda\""
        ;;
    "both")
        QEMU_CMD="$QEMU_CMD -initrd $ARTIFACTS_DIR/initramfs.gz"
        QEMU_CMD="$QEMU_CMD -drive file=$ARTIFACTS_DIR/root.img,format=raw,if=virtio"
        QEMU_CMD="$QEMU_CMD -append \"console=$QEMU_CONSOLE root=/dev/vda\""
        ;;
esac

# Add network (optional)
QEMU_CMD="$QEMU_CMD -netdev user,id=net0,hostfwd=tcp::2222-:22"
QEMU_CMD="$QEMU_CMD -device virtio-net-pci,netdev=net0"

echo "QEMU command:"
echo "$QEMU_CMD"
echo ""
echo "Starting QEMU..."
echo "Press Ctrl+A then X to exit QEMU"
echo ""

# Launch QEMU
eval "$QEMU_CMD"
