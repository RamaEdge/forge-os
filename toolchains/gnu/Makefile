# glibc cross toolchain build for ForgeOS
# Implements THE-46 (Toolchains) - Optional glibc track

# Configuration
ARCH ?= aarch64
BUILD_DIR ?= build
OUTPUT_DIR ?= ../output
SCRIPT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(abspath $(SCRIPT_DIR)/../..)

# Load version information
include $(SCRIPT_DIR)/../versions.mk

# Target configuration
TARGET := $(ARCH)-linux-gnu
TOOLCHAIN_OUTPUT := $(OUTPUT_DIR)/$(TARGET)

# Build configuration
JOBS := $(shell nproc 2>/dev/null || echo 4)

.PHONY: all clean check config

all:
	@echo "Building glibc toolchain for $(TARGET)..."
	@echo "Note: glibc toolchain is optional and requires crosstool-ng"
	@echo "For now, using system-provided cross-compiler if available"
	@mkdir -p $(BUILD_DIR)
	@if command -v $(TARGET)-gcc >/dev/null 2>&1; then \
		echo "System cross-compiler found: $(TARGET)-gcc"; \
		echo "Creating symlinks in $(TOOLCHAIN_OUTPUT)..."; \
		mkdir -p $(TOOLCHAIN_OUTPUT)/bin; \
		ln -sf $$(which $(TARGET)-gcc) $(TOOLCHAIN_OUTPUT)/bin/; \
		ln -sf $$(which $(TARGET)-g++) $(TOOLCHAIN_OUTPUT)/bin/; \
		ln -sf $$(which $(TARGET)-ar) $(TOOLCHAIN_OUTPUT)/bin/; \
		ln -sf $$(which $(TARGET)-strip) $(TOOLCHAIN_OUTPUT)/bin/; \
		ln -sf $$(which $(TARGET)-ranlib) $(TOOLCHAIN_OUTPUT)/bin/; \
		ln -sf $$(which $(TARGET)-nm) $(TOOLCHAIN_OUTPUT)/bin/; \
		ln -sf $$(which $(TARGET)-objcopy) $(TOOLCHAIN_OUTPUT)/bin/; \
		ln -sf $$(which $(TARGET)-objdump) $(TOOLCHAIN_OUTPUT)/bin/; \
		ln -sf $$(which $(TARGET)-readelf) $(TOOLCHAIN_OUTPUT)/bin/; \
		echo "glibc toolchain setup complete"; \
	else \
		echo "No system cross-compiler found for $(TARGET)"; \
		echo "Please install cross-compilation tools or use musl toolchain"; \
		echo "On macOS: brew install gcc-aarch64-elf"; \
		echo "On Ubuntu: sudo apt-get install gcc-aarch64-linux-gnu"; \
		exit 1; \
	fi

# Verify toolchain
check: all
	@echo "Verifying glibc toolchain..."
	@if [[ -f "$(TOOLCHAIN_OUTPUT)/bin/$(TARGET)-gcc" ]]; then \
		$(TOOLCHAIN_OUTPUT)/bin/$(TARGET)-gcc --version; \
		echo "Toolchain verification complete"; \
	else \
		echo "Toolchain not found at $(TOOLCHAIN_OUTPUT)/bin/$(TARGET)-gcc"; \
		exit 1; \
	fi

# Clean build artifacts
clean:
	@echo "Cleaning glibc toolchain build..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(TOOLCHAIN_OUTPUT)
	@echo "Clean complete"

# Show configuration
config:
	@echo "glibc toolchain Configuration:"
	@echo "  Target: $(TARGET)"
	@echo "  Build directory: $(BUILD_DIR)"
	@echo "  Output directory: $(TOOLCHAIN_OUTPUT)"
	@echo "  Jobs: $(JOBS)"
	@echo "  Note: Uses system-provided cross-compiler"
