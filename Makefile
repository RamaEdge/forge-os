# ForgeOS Build System
# Lightweight Linux forged for the edge

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
QEMU_ACCEL := hvf
QEMU_MEMORY := 1024
QEMU_CONSOLE := ttyAMA0

# Export for subprocesses
export SOURCE_DATE_EPOCH
export CROSS_COMPILE
export ARCH
export CC
export CXX
export AR
export STRIP

# Phony targets
.PHONY: all clean help toolchain kernel busybox packages rootfs initramfs image qemu-run sign release

# Default target
all: image

# Help target
help:
	@echo "ForgeOS Build System"
	@echo "==================="
	@echo ""
	@echo "Available targets:"
	@echo "  toolchain    - Build cross-compilation toolchains"
	@echo "  kernel       - Build Linux kernel"
	@echo "  busybox      - Build BusyBox userland"
	@echo "  packages     - Build APK packages and repository"
	@echo "  rootfs       - Create root filesystem"
	@echo "  initramfs    - Generate initramfs"
	@echo "  image        - Create final disk images"
	@echo "  qemu-run     - Launch QEMU for testing"
	@echo "  sign         - Sign all artifacts"
	@echo "  release      - Create release bundles"
	@echo "  clean        - Clean build artifacts"
	@echo "  help         - Show this help"
	@echo ""
	@echo "Configuration:"
	@echo "  PROFILE=$(PROFILE)  - System profile (core-min, core-net, service-sd)"
	@echo "  ARCH=$(ARCH)        - Target architecture (aarch64, x86_64)"
	@echo "  TOOLCHAIN=$(TOOLCHAIN) - Toolchain type (musl, gnu)"

# Toolchain target
toolchain:
	@echo "Building $(TOOLCHAIN) toolchain for $(ARCH)..."
	@mkdir -p $(BUILD_DIR)/toolchain
	@$(MAKE) -C toolchains/$(TOOLCHAIN) ARCH=$(ARCH) BUILD_DIR=$(BUILD_DIR)/toolchain

# Kernel target
kernel: toolchain
	@echo "Building Linux kernel for $(ARCH)..."
	@mkdir -p $(BUILD_DIR)/kernel
	@./scripts/build_kernel.sh $(ARCH) $(BUILD_DIR)/kernel $(ARTIFACTS_DIR)

# BusyBox target
busybox: toolchain
	@echo "Building BusyBox for $(ARCH)..."
	@mkdir -p $(BUILD_DIR)/busybox
	@./scripts/build_busybox.sh $(ARCH) $(BUILD_DIR)/busybox $(ARTIFACTS_DIR)

# Packages target
packages: toolchain
	@echo "Building APK packages for $(ARCH)..."
	@mkdir -p $(BUILD_DIR)/packages
	@./scripts/build_apk.sh iproute2 $(ARCH) $(BUILD_DIR)/packages $(ARTIFACTS_DIR)
	@./scripts/build_apk.sh chrony $(ARCH) $(BUILD_DIR)/packages $(ARTIFACTS_DIR)
	@./scripts/build_apk.sh dropbear $(ARCH) $(BUILD_DIR)/packages $(ARTIFACTS_DIR)
	@./scripts/build_apk.sh nftables $(ARCH) $(BUILD_DIR)/packages $(ARTIFACTS_DIR)
	@./scripts/build_apk.sh ca-certificates $(ARCH) $(BUILD_DIR)/packages $(ARTIFACTS_DIR)
	@./scripts/manage_repo.sh full $(ARCH)
	@./scripts/sign_packages.sh $(ARTIFACTS_DIR)/packages $(PROJECT_ROOT)/security/keys

# Root filesystem target
rootfs: busybox packages
	@echo "Creating root filesystem for profile $(PROFILE)..."
	@mkdir -p $(BUILD_DIR)/rootfs
	@./scripts/mk_rootfs.sh $(PROFILE) $(ARCH) $(BUILD_DIR)/rootfs $(ARTIFACTS_DIR)
	@./scripts/apply_profile.sh $(PROFILE) $(ARTIFACTS_DIR)/rootfs

# Initramfs target
initramfs: busybox
	@echo "Creating initramfs..."
	@mkdir -p $(BUILD_DIR)/initramfs
	@./scripts/mk_initramfs.sh $(PROFILE) $(ARCH) $(BUILD_DIR)/initramfs $(ARTIFACTS_DIR)

# Image target
image: rootfs initramfs
	@echo "Creating disk images..."
	@mkdir -p $(BUILD_DIR)/images
	@./scripts/mk_disk.sh $(PROFILE) $(ARCH) $(BUILD_DIR)/images $(ARTIFACTS_DIR)

# QEMU run target
qemu-run: image
	@echo "Launching QEMU..."
	@./scripts/qemu_run.sh $(PROFILE) $(ARCH) $(ARTIFACTS_DIR)

# Sign artifacts target
sign: image
	@echo "Signing artifacts..."
	@./scripts/sign_artifacts.sh $(ARTIFACTS_DIR)

# Release target
release: sign
	@echo "Creating release bundle..."
	@mkdir -p $(ARTIFACTS_DIR)/release
	@./scripts/mk_release.sh $(PROFILE) $(ARCH) $(FORGEOS_VERSION) $(ARTIFACTS_DIR)

# Clean target
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(ARTIFACTS_DIR)
	@echo "Clean complete."

# Development targets
dev-setup:
	@echo "Setting up development environment..."
	@git submodule update --init --recursive
	@echo "Development setup complete."

# Test targets
test-boot: qemu-run
	@echo "Boot test completed."

# Profile-specific targets
build-$(PROFILE): image
	@echo "Built profile $(PROFILE) successfully."

# Show configuration
config:
	@echo "ForgeOS Build Configuration:"
	@echo "  Version: $(FORGEOS_VERSION)"
	@echo "  Profile: $(PROFILE)"
	@echo "  Architecture: $(ARCH)"
	@echo "  Toolchain: $(TOOLCHAIN)"
	@echo "  Cross-compile: $(CROSS_COMPILE)"
	@echo "  Artifacts: $(ARTIFACTS_DIR)"
	@echo "  Build: $(BUILD_DIR)"
	@echo "  Source date: $(SOURCE_DATE_EPOCH)"
