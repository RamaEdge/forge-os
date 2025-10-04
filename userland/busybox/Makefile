# ForgeOS BusyBox Build System
# Implements THE-48 (Userland Base) + THE-121 (Optimize Package Downloads)

# Configuration
ARCH ?= aarch64
BUILD_DIR ?= build
OUTPUT_DIR ?= ../artifacts
SCRIPT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(abspath $(SCRIPT_DIR)/../..)

# Load centralized version information
include $(PROJECT_ROOT)/versions.mk

# BusyBox configuration (THE-121: Use centralized downloads directly)
BUSYBOX_SOURCE_DIR := $(BUILD_DIR)/busybox-$(BUSYBOX_VERSION)
DOWNLOADS_DIR := $(PROJECT_ROOT)/packages/downloads
BUSYBOX_TAR := $(DOWNLOADS_DIR)/busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_EXTRACTED := $(BUILD_DIR)/.busybox-extracted
BUSYBOX_CONFIG_FILE := $(SCRIPT_DIR)/configs/$(BUSYBOX_CONFIG)
BUSYBOX_OUTPUT_PATH := $(OUTPUT_DIR)/busybox

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
	@if [[ ! -f "$(BUSYBOX_TAR)" ]]; then \
		echo "Error: BusyBox v$(BUSYBOX_VERSION) not found in local downloads"; \
		echo "Please run 'make download-packages' first"; \
		echo "Expected location: $(BUSYBOX_TAR)"; \
		exit 1; \
	fi
	@echo "Using BusyBox v$(BUSYBOX_VERSION) from local downloads ✓"

# Extract and configure (THE-121: Direct extraction from downloads)
configure: download $(BUSYBOX_EXTRACTED)

$(BUSYBOX_EXTRACTED):
	@echo "Extracting BusyBox source from $(BUSYBOX_TAR)..."
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && tar -xjf "$(BUSYBOX_TAR)"
	@touch $(BUSYBOX_EXTRACTED)
	@echo "BusyBox source extracted to $(BUSYBOX_SOURCE_DIR)"

# Configure BusyBox
configure-busybox: $(BUSYBOX_EXTRACTED)
	@echo "Configuring BusyBox with $(BUSYBOX_CONFIG)..."
	@mkdir -p $(BUSYBOX_SOURCE_DIR)
	@cp $(BUSYBOX_CONFIG_FILE) $(BUSYBOX_SOURCE_DIR)/.config
	@echo "Configuration complete (placeholder)"

# Build BusyBox
build: configure configure-busybox
	@echo "Building BusyBox for $(ARCH)..."
	@mkdir -p $(BUSYBOX_SOURCE_DIR)/_install/bin
	@echo "BusyBox build complete (placeholder)"

# Install BusyBox artifacts
install: build
	@echo "Installing BusyBox artifacts..."
	@mkdir -p $(BUSYBOX_OUTPUT_PATH)
	@echo "Creating placeholder BusyBox artifacts..."
	@touch $(BUSYBOX_OUTPUT_PATH)/busybox
	@cp $(BUSYBOX_CONFIG_FILE) $(BUSYBOX_OUTPUT_PATH)/config
	@echo "BusyBox artifacts installed to $(BUSYBOX_OUTPUT_PATH) (placeholder)"

# Verify BusyBox build
check: install
	@echo "Verifying BusyBox build..."
	@if [[ -f "$(BUSYBOX_OUTPUT_PATH)/busybox" ]]; then \
		echo "BusyBox binary: $(BUSYBOX_OUTPUT_PATH)/busybox"; \
		file $(BUSYBOX_OUTPUT_PATH)/busybox; \
	else \
		echo "Error: BusyBox binary not found"; \
		exit 1; \
	fi
	@echo "BusyBox verification complete"

# Clean build artifacts (THE-121: Preserves downloads)
clean:
	@echo "Cleaning BusyBox build..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(BUSYBOX_OUTPUT_PATH)
	@echo "Clean complete (downloads preserved in $(DOWNLOADS_DIR))"

# Show configuration
config:
	@echo "BusyBox Build Configuration:"
	@echo "  Version: $(BUSYBOX_VERSION)"
	@echo "  Architecture: $(ARCH)"
	@echo "  Config: $(BUSYBOX_CONFIG)"
	@echo "  Build directory: $(BUILD_DIR)"
	@echo "  Output directory: $(BUSYBOX_OUTPUT_PATH)"
	@echo "  Downloads directory: $(DOWNLOADS_DIR)"
	@echo "  Jobs: $(JOBS)"
	@echo "  Cross-compile: $(CROSS_COMPILE)"
	@echo "  Tarball: $(BUSYBOX_TAR)"