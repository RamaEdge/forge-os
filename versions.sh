#!/bin/bash
# ForgeOS Centralized Version Management (Shell-compatible)
# Single source of truth for all component versions
# Implements THE-121 (Optimize Package Downloads)

# =============================================================================
# TOOLCHAIN VERSIONS
# =============================================================================

# Core toolchain components
export BINUTILS_VERSION="2.42"
export GCC_VERSION="15.2.0"
export MUSL_VERSION="1.2.4"
export GLIBC_VERSION="2.38"
export LINUX_HEADERS_VERSION="6.6"

# Toolchain build systems
export MUSL_CROSS_MAKE_VERSION="0.9.9"
export CROSSTOOL_NG_VERSION="1.25.0"

# =============================================================================
# KERNEL VERSIONS
# =============================================================================

# Linux kernel
export LINUX_VERSION="6.6.0"
export LINUX_VERSION_MAJOR="6"
export LINUX_VERSION_MINOR="6"
export LINUX_VERSION_PATCH="0"

# =============================================================================
# USERLAND VERSIONS
# =============================================================================

# BusyBox
export BUSYBOX_VERSION="1.36.1"
export BUSYBOX_VERSION_MAJOR="1"
export BUSYBOX_VERSION_MINOR="36"
export BUSYBOX_VERSION_PATCH="1"

# =============================================================================
# PACKAGE SYSTEM VERSIONS
# =============================================================================

# APK tools
export APK_TOOLS_VERSION="2.14.0"
export APK_TOOLS_VERSION_MAJOR="2"
export APK_TOOLS_VERSION_MINOR="14"
export APK_TOOLS_VERSION_PATCH="0"

# Core system packages
export IPROUTE2_VERSION="6.1.0"
export CHRONY_VERSION="4.3"
export DROPBEAR_VERSION="2022.83"
export NFTABLES_VERSION="1.0.7"
export CA_CERTIFICATES_VERSION="20230311"

# =============================================================================
# BUILD CONFIGURATION
# =============================================================================

# Build directories
export BUILD_DIR="build"
export OUTPUT_DIR="artifacts"
export REPO_DIR="packages/repo"

# Architecture
export ARCH="aarch64"
export TARGET_MUSL="aarch64-linux-musl"
export TARGET_GNU="aarch64-linux-gnu"

# =============================================================================
# REPOSITORY CONFIGURATION
# =============================================================================

export REPO_NAME="forgeos"
export REPO_VERSION="0.1.0"
export REPO_ARCH="aarch64"

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================

export SIGNING_KEY_TYPE="minisign"
export SIGNING_KEY_DIR="security/keys"
