# ForgeOS Centralized Version Management
# Single source of truth for all component versions
# Implements THE-121 (Optimize Package Downloads)

# =============================================================================
# TOOLCHAIN VERSIONS
# =============================================================================

# Core toolchain components
BINUTILS_VERSION := 2.42
GCC_VERSION := 15.2.0
MUSL_VERSION := 1.2.4
GLIBC_VERSION := 2.38
LINUX_HEADERS_VERSION := 6.6

# Toolchain build systems
MUSL_CROSS_MAKE_VERSION := 0.9.9
CROSSTOOL_NG_VERSION := 1.25.0

# =============================================================================
# KERNEL VERSIONS
# =============================================================================

# Linux kernel
LINUX_VERSION := 6.6.0
LINUX_VERSION_MAJOR := 6
LINUX_VERSION_MINOR := 6
LINUX_VERSION_PATCH := 0

# =============================================================================
# USERLAND VERSIONS
# =============================================================================

# BusyBox
BUSYBOX_VERSION := 1.36.1
BUSYBOX_VERSION_MAJOR := 1
BUSYBOX_VERSION_MINOR := 36
BUSYBOX_VERSION_PATCH := 1

# =============================================================================
# PACKAGE SYSTEM VERSIONS
# =============================================================================

# APK tools
APK_TOOLS_VERSION := 2.14.0
APK_TOOLS_VERSION_MAJOR := 2
APK_TOOLS_VERSION_MINOR := 14
APK_TOOLS_VERSION_PATCH := 0

# Core system packages
IPROUTE2_VERSION := 6.1.0
CHRONY_VERSION := 4.3
DROPBEAR_VERSION := 2022.83
NFTABLES_VERSION := 1.0.7
CA_CERTIFICATES_VERSION := 20230311

# =============================================================================
# BUILD CONFIGURATION
# =============================================================================

# Build directories
BUILD_DIR := build
OUTPUT_DIR := artifacts
REPO_DIR := packages/repo

# Architecture
ARCH := aarch64
TARGET_MUSL := $(ARCH)-linux-musl
TARGET_GNU := $(ARCH)-linux-gnu

# =============================================================================
# REPOSITORY CONFIGURATION
# =============================================================================

REPO_NAME := forgeos
REPO_VERSION := 0.1.0
REPO_ARCH := aarch64

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

SIGNING_KEY_TYPE := minisign
SIGNING_KEY_DIR := security/keys

# =============================================================================
# EXPORT ALL VERSIONS
# =============================================================================

# Toolchain exports
export BINUTILS_VERSION GCC_VERSION MUSL_VERSION GLIBC_VERSION LINUX_HEADERS_VERSION
export MUSL_CROSS_MAKE_VERSION CROSSTOOL_NG_VERSION

# Kernel exports
export LINUX_VERSION LINUX_VERSION_MAJOR LINUX_VERSION_MINOR LINUX_VERSION_PATCH

# Userland exports
export BUSYBOX_VERSION BUSYBOX_VERSION_MAJOR BUSYBOX_VERSION_MINOR BUSYBOX_VERSION_PATCH

# Package system exports
export APK_TOOLS_VERSION APK_TOOLS_VERSION_MAJOR APK_TOOLS_VERSION_MINOR APK_TOOLS_VERSION_PATCH
export IPROUTE2_VERSION CHRONY_VERSION DROPBEAR_VERSION NFTABLES_VERSION CA_CERTIFICATES_VERSION

# Build configuration exports
export BUILD_DIR OUTPUT_DIR REPO_DIR ARCH TARGET_MUSL TARGET_GNU

# Repository exports
export REPO_NAME REPO_VERSION REPO_ARCH

# Security exports
export SIGNING_KEY_TYPE SIGNING_KEY_DIR
