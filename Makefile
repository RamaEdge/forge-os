# ForgeOS Build System
# Lightweight Linux forged for the edge
# Single Makefile with essential targets only

# =============================================================================
# CONFIGURATION
# =============================================================================

# Version and metadata
FORGEOS_VERSION ?= 0.1.0
PROFILE ?= core-min
ARCH ?= aarch64
TOOLCHAIN ?= musl

# Build configuration
SOURCE_DATE_EPOCH ?= $(shell date +%s)
ARTIFACTS_DIR := artifacts
BUILD_DIR := build

# Cross-compilation settings
CROSS_COMPILE := $(ARCH)-linux-$(TOOLCHAIN)-
CC := $(CROSS_COMPILE)gcc
CXX := $(CROSS_COMPILE)g++
AR := $(CROSS_COMPILE)ar
STRIP := $(CROSS_COMPILE)strip

# QEMU settings
QEMU_ARCH := aarch64
QEMU_MACHINE := virt
QEMU_CPU := max

# =============================================================================
# BUILD PIPELINE TARGETS
# =============================================================================

# Main build target
image: rootfs initramfs
	@echo "Creating disk image..."
	@./scripts/mk_disk.sh $(PROFILE) $(ARCH) $(ARTIFACTS_DIR)
	@echo "Build complete: $(ARTIFACTS_DIR)/$(PROFILE)-$(ARCH).img"

# Root filesystem
rootfs: busybox packages
	@echo "Creating root filesystem..."
	@./scripts/mk_rootfs.sh $(PROFILE) $(ARCH) $(ARTIFACTS_DIR)
	@echo "Root filesystem created"

# Initramfs
initramfs: busybox
	@echo "Creating initramfs..."
	@./scripts/mk_initramfs.sh $(PROFILE) $(ARCH) $(ARTIFACTS_DIR)
	@echo "Initramfs created"

# BusyBox userland
busybox: toolchain
	@echo "Building BusyBox..."
	@./scripts/build_busybox.sh $(ARCH) $(TOOLCHAIN) $(ARTIFACTS_DIR)
	@echo "BusyBox build complete"

# Kernel
kernel: toolchain
	@echo "Building kernel..."
	@./scripts/build_kernel.sh $(ARCH) $(TOOLCHAIN) $(ARTIFACTS_DIR)
	@echo "Kernel build complete"

# Package system
packages: toolchain
	@echo "Building packages..."
	@./scripts/build_apk.sh $(ARCH) $(TOOLCHAIN) $(ARTIFACTS_DIR)
	@echo "Package build complete"

# Cross-compilation toolchain
toolchain: download-packages
	@echo "Building toolchain..."
	@./scripts/build_toolchain.sh $(ARCH) $(TOOLCHAIN) $(ARTIFACTS_DIR)
	@echo "Toolchain build complete"

# =============================================================================
# TESTING TARGETS
# =============================================================================

# QEMU testing
qemu-run: image
	@echo "Launching QEMU..."
	@./scripts/qemu_run.sh $(PROFILE) $(ARCH) $(ARTIFACTS_DIR)
	@echo "QEMU session ended"

# =============================================================================
# RELEASE TARGETS
# =============================================================================

# Sign artifacts
sign: image
	@echo "Signing artifacts..."
	@./scripts/sign_artifacts.sh $(ARTIFACTS_DIR)
	@echo "Artifacts signed"

# Create release bundle
release: sign
	@echo "Creating release bundle..."
	@./scripts/mk_release.sh $(PROFILE) $(ARCH) $(FORGEOS_VERSION) $(ARTIFACTS_DIR)
	@echo "Release bundle created"

# =============================================================================
# UTILITY TARGETS
# =============================================================================

# Download packages
download-packages:
	@echo "Downloading packages..."
	@bash -c '. ./scripts/versions.sh && ./scripts/download_packages.sh'
	@echo "Package download complete"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(ARTIFACTS_DIR)
	@echo "Clean complete"

# Clean individual components
clean-toolchain:
	@echo "Cleaning toolchain artifacts..."
	@rm -rf $(ARTIFACTS_DIR)/toolchain
	@rm -rf $(BUILD_DIR)/toolchain
	@echo "Toolchain clean complete"

clean-kernel:
	@echo "Cleaning kernel artifacts..."
	@rm -rf $(ARTIFACTS_DIR)/kernel
	@rm -rf $(BUILD_DIR)/kernel-*
	@echo "Kernel clean complete"

clean-busybox:
	@echo "Cleaning BusyBox artifacts..."
	@rm -rf $(ARTIFACTS_DIR)/busybox
	@rm -rf $(BUILD_DIR)/busybox
	@echo "BusyBox clean complete"

clean-packages:
	@echo "Cleaning package artifacts..."
	@rm -rf $(ARTIFACTS_DIR)/packages
	@rm -rf $(BUILD_DIR)/packages
	@echo "Packages clean complete"

clean-rootfs:
	@echo "Cleaning rootfs artifacts..."
	@rm -rf $(ARTIFACTS_DIR)/rootfs
	@rm -rf $(ARTIFACTS_DIR)/initramfs*
	@echo "Rootfs clean complete"

clean-images:
	@echo "Cleaning image artifacts..."
	@rm -rf $(ARTIFACTS_DIR)/images
	@rm -rf $(ARTIFACTS_DIR)/*.img
	@rm -rf $(ARTIFACTS_DIR)/*.qcow2
	@echo "Images clean complete"

# Show help
help:
	@echo "ForgeOS Build System - Essential Targets"
	@echo ""
	@echo "Build Pipeline:"
	@echo "  download-packages  - Download all required packages"
	@echo "  toolchain          - Build cross-compilation toolchain"
	@echo "  kernel             - Build Linux kernel"
	@echo "  busybox            - Build BusyBox userland"
	@echo "  packages           - Build package system"
	@echo "  rootfs             - Create root filesystem"
	@echo "  initramfs          - Create initramfs"
	@echo "  image              - Create final disk image (default)"
	@echo ""
	@echo "Testing:"
	@echo "  qemu-run           - Launch QEMU for testing"
	@echo ""
	@echo "Release:"
	@echo "  sign               - Sign all artifacts"
	@echo "  release            - Create release bundle"
	@echo ""
	@echo "Utilities:"
	@echo "  clean              - Clean all build artifacts"
	@echo "  clean-toolchain    - Clean toolchain artifacts"
	@echo "  clean-kernel       - Clean kernel artifacts"
	@echo "  clean-busybox      - Clean BusyBox artifacts"
	@echo "  clean-packages     - Clean package artifacts"
	@echo "  clean-rootfs       - Clean rootfs artifacts"
	@echo "  clean-images       - Clean image artifacts"
	@echo "  help               - Show this help"
	@echo ""
	@echo "Configuration:"
	@echo "  PROFILE=$(PROFILE)  - System profile (core-min, core-net, service-sd)"
	@echo "  ARCH=$(ARCH)        - Target architecture (aarch64, x86_64)"
	@echo "  TOOLCHAIN=$(TOOLCHAIN) - Toolchain type (musl, gnu)"
	@echo ""
	@echo "Examples:"
	@echo "  make image                    # Build everything"
	@echo "  make PROFILE=core-net image   # Build with networking profile"
	@echo "  make ARCH=x86_64 image        # Build for x86_64"
	@echo "  make qemu-run                 # Build and test in QEMU"

# =============================================================================
# PHONY TARGETS
# =============================================================================

.PHONY: image rootfs initramfs busybox kernel packages toolchain
.PHONY: qemu-run sign release download-packages clean help
.PHONY: clean-toolchain clean-kernel clean-busybox clean-packages clean-rootfs clean-images
