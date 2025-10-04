#!/bin/bash
# ForgeOS Package System Version Management (Shell-compatible)
# Pinned versions for reproducible builds

# APK tools version
export APK_TOOLS_VERSION="2.14.0"
export APK_TOOLS_VERSION_MAJOR="2"
export APK_TOOLS_VERSION_MINOR="14"
export APK_TOOLS_VERSION_PATCH="0"

# Base package versions
export IPROUTE2_VERSION="6.1.0"
export CHRONY_VERSION="4.3"
export DROPBEAR_VERSION="2022.83"
export NFTABLES_VERSION="1.0.7"
export CA_CERTIFICATES_VERSION="20230311"

# Build configuration
export PACKAGES_BUILD_DIR="build"
export PACKAGES_OUTPUT_DIR="../artifacts"
export PACKAGES_REPO_DIR="repo"

# Repository configuration
export REPO_NAME="forgeos"
export REPO_VERSION="0.1.0"
export REPO_ARCH="aarch64"

# Signing configuration
export SIGNING_KEY_TYPE="minisign"
export SIGNING_KEY_DIR="../security/keys"
