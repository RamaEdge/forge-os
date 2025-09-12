# ForgeOS Kernel Version Management
# Pinned versions for reproducible builds

# Linux kernel version
LINUX_VERSION := 6.6.0
LINUX_VERSION_MAJOR := 6
LINUX_VERSION_MINOR := 6
LINUX_VERSION_PATCH := 0

# Kernel configuration
KERNEL_CONFIG := aarch64_defconfig
KERNEL_ARCH := arm64

# Build configuration
KERNEL_BUILD_DIR := build
KERNEL_OUTPUT_DIR := ../artifacts

# Security features
KERNEL_SECURITY_FEATURES := KASLR STACKPROTECTOR_STRONG SLUB_DEBUG HARDENED_USERCOPY APPARMOR SECCOMP

# Export versions for use in build scripts
export LINUX_VERSION
export LINUX_VERSION_MAJOR
export LINUX_VERSION_MINOR
export LINUX_VERSION_PATCH
export KERNEL_CONFIG
export KERNEL_ARCH
export KERNEL_BUILD_DIR
export KERNEL_OUTPUT_DIR
export KERNEL_SECURITY_FEATURES
