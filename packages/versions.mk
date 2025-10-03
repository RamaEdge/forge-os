# ForgeOS Package System Version Management
# Pinned versions for reproducible builds

# APK tools version
APK_TOOLS_VERSION := 2.14.0
APK_TOOLS_VERSION_MAJOR := 2
APK_TOOLS_VERSION_MINOR := 14
APK_TOOLS_VERSION_PATCH := 0

# Base package versions
IPROUTE2_VERSION := 6.1.0
CHRONY_VERSION := 4.3
DROPBEAR_VERSION := 2022.83
NFTABLES_VERSION := 1.0.7
CA_CERTIFICATES_VERSION := 20230311

# Build configuration
PACKAGES_BUILD_DIR := build
PACKAGES_OUTPUT_DIR := ../artifacts
PACKAGES_REPO_DIR := repo

# Repository configuration
REPO_NAME := forgeos
REPO_VERSION := 0.1.0
REPO_ARCH := aarch64

# Signing configuration
SIGNING_KEY_TYPE := minisign
SIGNING_KEY_DIR := ../security/keys

# Export versions for use in build scripts
export APK_TOOLS_VERSION
export APK_TOOLS_VERSION_MAJOR
export APK_TOOLS_VERSION_MINOR
export APK_TOOLS_VERSION_PATCH
export IPROUTE2_VERSION
export CHRONY_VERSION
export DROPBEAR_VERSION
export NFTABLES_VERSION
export CA_CERTIFICATES_VERSION
export PACKAGES_BUILD_DIR
export PACKAGES_OUTPUT_DIR
export PACKAGES_REPO_DIR
export REPO_NAME
export REPO_VERSION
export REPO_ARCH
export SIGNING_KEY_TYPE
export SIGNING_KEY_DIR
