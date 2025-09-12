# musl-cross-make toolchain build for ForgeOS
# Implements THE-46 (Toolchains)

# Configuration
ARCH ?= aarch64
BUILD_DIR ?= build
OUTPUT_DIR ?= ../output
SCRIPT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(abspath $(SCRIPT_DIR)/../..)

# Load version information
include $(SCRIPT_DIR)/../versions.mk

# musl-cross-make configuration
MUSL_CROSS_MAKE_DIR := $(BUILD_DIR)/musl-cross-make
MUSL_CROSS_MAKE_URL := https://github.com/richfelker/musl-cross-make/archive/v$(MUSL_CROSS_MAKE_VERSION).tar.gz
MUSL_CROSS_MAKE_TAR := $(BUILD_DIR)/musl-cross-make-$(MUSL_CROSS_MAKE_VERSION).tar.gz

# Target configuration
TARGET := $(ARCH)-linux-musl
TOOLCHAIN_OUTPUT := $(OUTPUT_DIR)/$(TARGET)

# Build configuration
JOBS := $(shell nproc 2>/dev/null || echo 4)

.PHONY: all clean download configure build install check

all: install

# Download musl-cross-make
download: $(MUSL_CROSS_MAKE_TAR)

$(MUSL_CROSS_MAKE_TAR):
	@echo "Downloading musl-cross-make v$(MUSL_CROSS_MAKE_VERSION)..."
	@mkdir -p $(BUILD_DIR)
	@curl -L -o "$@" "$(MUSL_CROSS_MAKE_URL)"
	@echo "Downloaded: $@"

# Extract and configure
configure: download
	@echo "Extracting and configuring musl-cross-make..."
	@cd $(BUILD_DIR) && tar -xzf $(notdir $(MUSL_CROSS_MAKE_TAR))
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

# Clean build artifacts
clean:
	@echo "Cleaning musl toolchain build..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(TOOLCHAIN_OUTPUT)
	@echo "Clean complete"

# Show configuration
config:
	@echo "musl-cross-make Configuration:"
	@echo "  Target: $(TARGET)"
	@echo "  Build directory: $(BUILD_DIR)"
	@echo "  Output directory: $(TOOLCHAIN_OUTPUT)"
	@echo "  Jobs: $(JOBS)"
	@echo "  musl-cross-make version: $(MUSL_CROSS_MAKE_VERSION)"
