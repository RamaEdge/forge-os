# ForgeOS Userland Version Management
# Pinned versions for reproducible builds

# BusyBox version
BUSYBOX_VERSION := 1.36.1
BUSYBOX_VERSION_MAJOR := 1
BUSYBOX_VERSION_MINOR := 36
BUSYBOX_VERSION_PATCH := 1

# Build configuration
USERLAND_BUILD_DIR := build
USERLAND_OUTPUT_DIR := ../artifacts

# BusyBox configuration
BUSYBOX_CONFIG := busybox_defconfig
BUSYBOX_ARCH := aarch64

# Required applets
BUSYBOX_CORE_APPLETS := init sh mdev udhcpc
BUSYBOX_NETWORK_APPLETS := ifconfig ip syslogd klogd
BUSYBOX_SYSTEM_APPLETS := ps mount umount chmod chown
BUSYBOX_UTILITY_APPLETS := ls cat echo mkdir rmdir

# Export versions for use in build scripts
export BUSYBOX_VERSION
export BUSYBOX_VERSION_MAJOR
export BUSYBOX_VERSION_MINOR
export BUSYBOX_VERSION_PATCH
export USERLAND_BUILD_DIR
export USERLAND_OUTPUT_DIR
export BUSYBOX_CONFIG
export BUSYBOX_ARCH
export BUSYBOX_CORE_APPLETS
export BUSYBOX_NETWORK_APPLETS
export BUSYBOX_SYSTEM_APPLETS
export BUSYBOX_UTILITY_APPLETS
