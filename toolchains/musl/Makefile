# musl-cross-make toolchain build for ForgeOS
# Implements THE-46 (Toolchains) + THE-121 (Optimize Package Downloads)

# Configuration
ARCH ?= aarch64
BUILD_DIR ?= build
OUTPUT_DIR ?= ../output
SCRIPT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(abspath $(SCRIPT_DIR)/../..)

# Load centralized version information
include $(PROJECT_ROOT)/versions.mk

# musl-cross-make configuration (THE-121: Use centralized downloads directly)
MUSL_CROSS_MAKE_DIR := $(BUILD_DIR)/musl-cross-make
DOWNLOADS_DIR := $(PROJECT_ROOT)/packages/downloads
MUSL_CROSS_MAKE_TAR := $(DOWNLOADS_DIR)/v$(MUSL_CROSS_MAKE_VERSION).tar.gz
MUSL_CROSS_MAKE_EXTRACTED := $(BUILD_DIR)/.musl-cross-make-extracted

# Target configuration
TARGET := $(ARCH)-linux-musl
TOOLCHAIN_OUTPUT := $(OUTPUT_DIR)/$(TARGET)

# Build configuration
JOBS := $(shell nproc 2>/dev/null || echo 4)

.PHONY: all clean download configure build install check

all: install

# Download check (THE-121: Verify local downloads exist)
download:
	@if [[ ! -f "$(MUSL_CROSS_MAKE_TAR)" ]]; then \
		echo "Error: musl-cross-make v$(MUSL_CROSS_MAKE_VERSION) not found in local downloads"; \
		echo "Please run 'make download-packages' first"; \
		echo "Expected location: $(MUSL_CROSS_MAKE_TAR)"; \
		exit 1; \
	fi
	@echo "Using musl-cross-make v$(MUSL_CROSS_MAKE_VERSION) from local downloads ✓"

# Extract and configure (THE-121: Direct extraction from downloads)
configure: download $(MUSL_CROSS_MAKE_EXTRACTED)

$(MUSL_CROSS_MAKE_EXTRACTED):
	@echo "Extracting musl-cross-make from $(MUSL_CROSS_MAKE_TAR)..."
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && tar -xzf "$(MUSL_CROSS_MAKE_TAR)"
	@cd $(BUILD_DIR) && rm -rf musl-cross-make && mv musl-cross-make-$(MUSL_CROSS_MAKE_VERSION) musl-cross-make
	@cd $(MUSL_CROSS_MAKE_DIR) && \
		echo "TARGET = $(TARGET)" > config.mak && \
		echo "OUTPUT = $(abspath $(TOOLCHAIN_OUTPUT))" >> config.mak && \
		echo "COMMON_CONFIG += CC=\"gcc -static --static\"" >> config.mak && \
		echo "COMMON_CONFIG += CXX=\"g++ -static --static\"" >> config.mak && \
		echo "COMMON_CONFIG += --disable-shared" >> config.mak && \
		echo "COMMON_CONFIG += --enable-static" >> config.mak && \
		echo "COMMON_CONFIG += --disable-multilib" >> config.mak && \
		echo "GCC_CONFIG += --enable-languages=c,c++" >> config.mak && \
		echo "GCC_CONFIG += --disable-libquadmath" >> config.mak && \
		echo "GCC_CONFIG += --disable-libssp" >> config.mak && \
		echo "GCC_CONFIG += --disable-libgomp" >> config.mak && \
		echo "GCC_CONFIG += --disable-libmudflap" >> config.mak && \
		echo "GCC_CONFIG += --disable-libsanitizer" >> config.mak && \
		echo "GCC_CONFIG += --disable-libatomic" >> config.mak && \
		echo "GCC_CONFIG += --disable-libstdcxx-pch" >> config.mak && \
		echo "MUSL_CONFIG += --enable-debug" >> config.mak && \
		echo "MUSL_CONFIG += --enable-optimize" >> config.mak
	@touch $(MUSL_CROSS_MAKE_EXTRACTED)
	@echo "Configuration complete"

# Build toolchain
build: configure
	@echo "Building musl toolchain for $(TARGET)..."
	@cd $(MUSL_CROSS_MAKE_DIR) && make -j$(JOBS)
	@echo "Toolchain build complete"

# Install toolchain
install: build
	@echo "Installing toolchain to $(TOOLCHAIN_OUTPUT)..."
	@mkdir -p $(TOOLCHAIN_OUTPUT)
	@cd $(MUSL_CROSS_MAKE_DIR) && make install
	@echo "Toolchain installed to $(TOOLCHAIN_OUTPUT)"

# Verify toolchain
check: install
	@echo "Verifying toolchain..."
	@$(TOOLCHAIN_OUTPUT)/bin/$(TARGET)-gcc --version
	@$(TOOLCHAIN_OUTPUT)/bin/$(TARGET)-gcc -print-sysroot
	@echo "Toolchain verification complete"

# Clean build artifacts (THE-121: Preserves downloads)
clean:
	@echo "Cleaning musl toolchain build..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(TOOLCHAIN_OUTPUT)
	@echo "Clean complete (downloads preserved in $(DOWNLOADS_DIR))"

# Show configuration
config:
	@echo "musl-cross-make Configuration:"
	@echo "  Target: $(TARGET)"
	@echo "  Build directory: $(BUILD_DIR)"
	@echo "  Output directory: $(TOOLCHAIN_OUTPUT)"
	@echo "  Downloads directory: $(DOWNLOADS_DIR)"
	@echo "  Jobs: $(JOBS)"
	@echo "  musl-cross-make version: $(MUSL_CROSS_MAKE_VERSION)"
	@echo "  Tarball: $(MUSL_CROSS_MAKE_TAR)"