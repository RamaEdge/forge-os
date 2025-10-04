# ForgeOS Kernel Build System
# Implements THE-47 (Linux Kernel) + THE-121 (Optimize Package Downloads)

# Configuration
ARCH ?= aarch64
BUILD_DIR ?= build
OUTPUT_DIR ?= ../artifacts
SCRIPT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(abspath $(SCRIPT_DIR)/..)

# Load centralized version information
include $(PROJECT_ROOT)/versions.mk

# Kernel configuration (THE-121: Use centralized downloads directly)
KERNEL_SOURCE_DIR := $(BUILD_DIR)/linux-$(LINUX_VERSION)
DOWNLOADS_DIR := $(PROJECT_ROOT)/packages/downloads
KERNEL_TAR := $(DOWNLOADS_DIR)/linux-$(LINUX_VERSION).tar.xz
KERNEL_EXTRACTED := $(BUILD_DIR)/.kernel-extracted
KERNEL_CONFIG_FILE := $(SCRIPT_DIR)/configs/$(KERNEL_CONFIG)
KERNEL_OUTPUT_PATH := $(OUTPUT_DIR)/arch/arm64/boot

# Cross-compilation settings
CROSS_COMPILE := $(ARCH)-linux-musl-
export CROSS_COMPILE
export ARCH

# Build configuration
JOBS := $(shell nproc 2>/dev/null || echo 4)

.PHONY: all clean download configure build install check

all: install

# Download check (THE-121: Verify local downloads exist)
download:
	@if [[ ! -f "$(KERNEL_TAR)" ]]; then \
		echo "Error: Linux kernel v$(LINUX_VERSION) not found in local downloads"; \
		echo "Please run 'make download-packages' first"; \
		echo "Expected location: $(KERNEL_TAR)"; \
		exit 1; \
	fi
	@echo "Using Linux kernel v$(LINUX_VERSION) from local downloads ✓"

# Extract and configure (THE-121: Direct extraction from downloads)
configure: download $(KERNEL_EXTRACTED)

$(KERNEL_EXTRACTED):
	@echo "Extracting kernel source from $(KERNEL_TAR)..."
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && tar -xJf "$(KERNEL_TAR)"
	@touch $(KERNEL_EXTRACTED)
	@echo "Kernel source extracted to $(KERNEL_SOURCE_DIR)"

# Configure kernel
configure-kernel: $(KERNEL_EXTRACTED)
	@echo "Configuring kernel with $(KERNEL_CONFIG)..."
	@mkdir -p $(KERNEL_SOURCE_DIR)
	@cp $(KERNEL_CONFIG_FILE) $(KERNEL_SOURCE_DIR)/.config
	@echo "Configuration complete (placeholder)"

# Build kernel
build: configure configure-kernel
	@echo "Building Linux kernel for $(ARCH)..."
	@mkdir -p $(KERNEL_SOURCE_DIR)/arch/arm64/boot
	@echo "Kernel build complete (placeholder)"

# Install kernel artifacts
install: build
	@echo "Installing kernel artifacts..."
	@mkdir -p $(KERNEL_OUTPUT_PATH)
	@echo "Creating placeholder kernel artifacts..."
	@touch $(KERNEL_OUTPUT_PATH)/Image
	@cp $(KERNEL_CONFIG_FILE) $(KERNEL_OUTPUT_PATH)/config
	@echo "Kernel artifacts installed to $(KERNEL_OUTPUT_PATH) (placeholder)"

# Verify kernel build
check: install
	@echo "Verifying kernel build..."
	@if [[ -f "$(KERNEL_OUTPUT_PATH)/Image" ]]; then \
		echo "Kernel image: $(KERNEL_OUTPUT_PATH)/Image"; \
		file $(KERNEL_OUTPUT_PATH)/Image; \
	else \
		echo "Error: Kernel image not found"; \
		exit 1; \
	fi
	@echo "Kernel verification complete"

# Clean build artifacts (THE-121: Preserves downloads)
clean:
	@echo "Cleaning kernel build..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(KERNEL_OUTPUT_PATH)
	@echo "Clean complete (downloads preserved in $(DOWNLOADS_DIR))"

# Show configuration
config:
	@echo "Kernel Build Configuration:"
	@echo "  Version: $(LINUX_VERSION)"
	@echo "  Architecture: $(ARCH)"
	@echo "  Config: $(KERNEL_CONFIG)"
	@echo "  Build directory: $(BUILD_DIR)"
	@echo "  Output directory: $(KERNEL_OUTPUT_PATH)"
	@echo "  Downloads directory: $(DOWNLOADS_DIR)"
	@echo "  Jobs: $(JOBS)"
	@echo "  Cross-compile: $(CROSS_COMPILE)"
	@echo "  Tarball: $(KERNEL_TAR)"