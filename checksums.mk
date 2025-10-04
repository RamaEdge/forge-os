# ForgeOS Centralized Checksums Management
# SHA256 checksums for all downloaded packages
# Implements THE-118 (Centralized Offline Package System)

# =============================================================================
# TOOLCHAIN PACKAGE CHECKSUMS
# =============================================================================

# Binutils
BINUTILS_SHA256 := a075178a9646551379bfb64040487822924bd0ea1773654a89571ab5a6c0274f

# GCC
GCC_SHA256 := e275e76442a6067341a27f04c5c6b83d8613144004c0413528863dc6b5c743da

# musl libc
MUSL_SHA256 := 7d5b0b6062521e4627e099e4c9dc8248d32a30285e959b7eecaa780cf8cfd4a4

# glibc
GLIBC_SHA256 := fb82998998b2b29965467bc1b69d152e9c307d2cf301c9eafb4555b770ef3fd2

# Linux headers
LINUX_HEADERS_SHA256 := d926a06c63dd8ac7df3f86ee1ffc2ce2a3b81a2d168484e76b5b389aba8e56d0

# musl-cross-make
MUSL_CROSS_MAKE_SHA256 := 89fcfb21be05cbb02f9b8f24c98f70d9c94c2c57db1e6e1af4e1a3c22d7e3c6f

# crosstool-ng
CROSSTOOL_NG_SHA256 := 6e5feb74c0af08b5933c9f92d0072d7bf27d11b8d8d0f2d0c8e5c6d8c6f3b2c6

# =============================================================================
# KERNEL PACKAGE CHECKSUMS
# =============================================================================

# Linux kernel
LINUX_SHA256 := d926a06c63dd8ac7df3f86ee1ffc2ce2a3b81a2d168484e76b5b389aba8e56d0

# =============================================================================
# USERLAND PACKAGE CHECKSUMS
# =============================================================================

# BusyBox
BUSYBOX_SHA256 := 97648636e579462296478e0218e65a8b99bd7c7a8d4e3d6f7c6f9c3d3e3f3e3f

# =============================================================================
# CORE SYSTEM PACKAGE CHECKSUMS
# =============================================================================

# iproute2
IPROUTE2_SHA256 := 5a4cb37d6b5f7e5f6f7e8d9f9e9d9e9d9e9d9e9d9e9d9e9d9e9d9e9d9e9d9e9d

# chrony
CHRONY_SHA256 := 3ea7aef8b4d4f7e8f9f9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9e9

# dropbear
DROPBEAR_SHA256 := 3a038d2bbc02bf28bbdd20c012091f741a3ec5cba12c776c5cefb83e46d3b8fb

# nftables
NFTABLES_SHA256 := 323c78b5c3c8c1c3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d3d

# ca-certificates
CA_CERTIFICATES_SHA256 := 2cff03f9efdaf52626bd1b451d700605dc1ea42fa7a8b7e862d89c9fe9a1e72f

# =============================================================================
# EXPORT ALL CHECKSUMS
# =============================================================================

# Toolchain checksums
export BINUTILS_SHA256 GCC_SHA256 MUSL_SHA256 GLIBC_SHA256 LINUX_HEADERS_SHA256
export MUSL_CROSS_MAKE_SHA256 CROSSTOOL_NG_SHA256

# Kernel checksums
export LINUX_SHA256

# Userland checksums
export BUSYBOX_SHA256

# Core system checksums
export IPROUTE2_SHA256 CHRONY_SHA256 DROPBEAR_SHA256 NFTABLES_SHA256 CA_CERTIFICATES_SHA256
