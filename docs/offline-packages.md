# ForgeOS Offline Package System

**Implementation**: THE-118 (Centralized Offline Package System)  
**Status**: Complete  
**Version**: 1.0.0

## Overview

ForgeOS implements a centralized offline package download system that enables fully air-gapped builds. All required packages are downloaded upfront with integrity verification, eliminating internet dependency during builds.

## Motivation

### Problems Solved

- **Internet Dependency**: Builds no longer require internet connectivity
- **Slow Builds**: Network delays eliminated during compilation
- **Air-Gapped Environments**: Enables builds in secure, isolated networks
- **Build Reliability**: No failures due to network issues
- **Package Integrity**: Cryptographic verification of all downloads

### Benefits

✅ **Offline Builds**: Complete air-gapped build capability  
✅ **Faster Builds**: No network delays during compilation  
✅ **Reproducible**: Verified package integrity with SHA256  
✅ **Reliable**: Robust download with retry logic  
✅ **Secure**: Package integrity verification  
✅ **CI/CD Ready**: Predictable build times  

## Architecture

### Directory Structure

```
packages/
├── downloads/              # Downloaded source tarballs
│   ├── binutils-2.42.tar.xz
│   ├── gcc-13.2.0.tar.xz
│   ├── musl-1.2.4.tar.gz
│   ├── linux-6.6.0.tar.xz
│   ├── busybox-1.36.1.tar.bz2
│   ├── iproute2-6.1.0.tar.xz
│   ├── chrony-4.3.tar.gz
│   ├── dropbear-2022.83.tar.bz2
│   ├── nftables-1.0.7.tar.bz2
│   └── [35+ packages total]
├── checksums.mk           # SHA256 checksums for verification
├── versions.mk            # Package versions (existing)
├── sources/               # APKBUILD files (existing)
└── repo/                  # APK repository (existing)
```

### Components

#### 1. Download Infrastructure

**packages/downloads/**
- Central storage for all source tarballs
- Organized by package name and version
- Shared across all build targets

**packages/checksums.mk**
- SHA256 checksums for all packages
- Used for integrity verification
- Prevents tampered downloads

#### 2. Download Script

**scripts/download_packages.sh**
- Centralized download manager
- Retry logic with 3 attempts
- Progress indicators
- Checksum verification
- Colored output
- Download statistics

#### 3. Build System Integration

**Makefile Targets**
- `make download-packages` - Download all packages
- `make clean-downloads` - Clean downloaded packages
- Integrated with help system

## Usage

### Basic Workflow

#### 1. Download Packages (One-Time)

```bash
# Download all required packages
make download-packages
```

**Output:**
```
ForgeOS Centralized Package Download System
Starting package download...

═══════════════════════════════════════════════════
  Toolchain Packages
═══════════════════════════════════════════════════
[INFO] Downloading: binutils-2.42.tar.xz
[✓] Downloaded: binutils-2.42.tar.xz
[INFO] Downloading: gcc-13.2.0.tar.xz
[✓] Downloaded: gcc-13.2.0.tar.xz
...

═══════════════════════════════════════════════════
  Download Summary
═══════════════════════════════════════════════════

  Total packages:      15
  Downloaded:          15
  Cached (verified):   0
  Failed:              0

[✓] All packages downloaded and verified successfully! ✨
```

#### 2. Build Offline

```bash
# Now build without internet
make all PROFILE=core-min ARCH=aarch64
```

**No internet required!** All packages are already downloaded and verified.

### Advanced Usage

#### Verify Downloaded Packages

```bash
# List downloaded packages
ls -lh packages/downloads/

# Verify checksums manually
cd packages/downloads
sha256sum binutils-2.42.tar.xz
```

#### Re-download Specific Package

```bash
# Remove package to force re-download
rm packages/downloads/binutils-2.42.tar.xz

# Re-run download
make download-packages
```

#### Clean and Re-download All

```bash
# Clean all downloads
make clean-downloads

# Re-download everything
make download-packages
```

### Air-Gapped Environment

#### Preparation (with internet)

```bash
# On a machine with internet:
cd forgeos
make download-packages

# Create tarball
tar -czf forgeos-packages.tar.gz packages/downloads/
```

#### Transfer and Build (without internet)

```bash
# On air-gapped machine:
cd forgeos
tar -xzf forgeos-packages.tar.gz

# Build offline
make all PROFILE=core-min ARCH=aarch64
```

## Package List

### Toolchain Packages (7)

| Package | Version | Size | Purpose |
|---------|---------|------|---------|
| binutils | 2.42 | ~22MB | Binary utilities |
| gcc | 13.2.0 | ~85MB | C/C++ compiler |
| musl | 1.2.4 | ~1MB | C standard library |
| glibc | 2.38 | ~18MB | GNU C library |
| linux-headers | 6.6 | ~8MB | Kernel headers |
| musl-cross-make | 0.9.9 | ~50KB | Cross-compiler build |
| crosstool-ng | 1.25.0 | ~2MB | Toolchain generator |

### Kernel Packages (1)

| Package | Version | Size | Purpose |
|---------|---------|------|---------|
| linux | 6.6.0 | ~138MB | Linux kernel source |

### Userland Packages (1)

| Package | Version | Size | Purpose |
|---------|---------|------|---------|
| busybox | 1.36.1 | ~2MB | Userland utilities |

### Core System Packages (5)

| Package | Version | Size | Purpose |
|---------|---------|------|---------|
| iproute2 | 6.1.0 | ~1MB | Network utilities |
| chrony | 4.3 | ~600KB | NTP client/server |
| dropbear | 2022.83 | ~1MB | SSH server |
| nftables | 1.0.7 | ~1MB | Firewall |
| ca-certificates | 20230311 | ~200KB | CA certificates |

**Total: 15 core packages (~280MB)**

Additional packages available for specific profiles.

## Download Script Features

### Retry Logic

```bash
# Automatic retry on failure
for attempt in 1 2 3; do
    if download_succeeds; then
        break
    else
        log "Attempt $attempt failed, retrying..."
        sleep 2
    fi
done
```

### Checksum Verification

```bash
# SHA256 verification
actual_sha256=$(sha256sum file | cut -d' ' -f1)
if [[ "$actual_sha256" == "$expected_sha256" ]]; then
    log "✓ Verified"
else
    log "✗ Checksum mismatch"
    return 1
fi
```

### Caching

```bash
# Skip already downloaded files
if [[ -f "$filepath" ]]; then
    if verify_checksum "$filepath"; then
        log "✓ Cached: $filename"
        return 0
    fi
fi
```

### Progress Tracking

```bash
# Download counters
Total packages:      15
Downloaded:          10
Cached (verified):   5
Failed:              0
```

## Security Features

### Integrity Verification

- **SHA256 Checksums**: All packages verified
- **Automatic Verification**: Before and after download
- **Tamper Detection**: Invalid files rejected
- **Secure Downloads**: HTTPS-only with certificate verification

### Audit Trail

```bash
# All operations logged
[INFO] Downloading: package-1.0.0.tar.gz
[✓] Downloaded: package-1.0.0.tar.gz
[INFO] Checksum verified
```

### Error Handling

```bash
# Robust error handling
- Connection timeout: 30s
- Max download time: 600s (10 minutes)
- Retry on failure: 3 attempts
- Checksum verification: Always
- Graceful degradation: Continue on individual failures
```

## Build System Changes

### Before (THE-118)

```bash
# Internet required for each build
make kernel    # Downloads kernel source with curl
make busybox   # Downloads BusyBox source with curl
make packages  # Downloads package sources with curl
```

**Problems:**
- Network delays
- Build failures on network issues
- Cannot build offline
- Slow CI/CD

### After (THE-118)

```bash
# One-time download
make download-packages  # Download all packages upfront

# Offline builds
make kernel            # Extracts from local downloads
make busybox           # Extracts from local downloads
make packages          # Uses local package sources
```

**Implementation:**
- `toolchains/musl/Makefile` - Uses `packages/downloads/` for musl-cross-make
- `kernel/Makefile` - Extracts kernel from local downloads
- `userland/busybox/Makefile` - Extracts BusyBox from local downloads
- All Makefiles check for local packages first
- Clear error messages if packages not downloaded

**Benefits:**
- No network delays
- Reliable builds
- Offline capable
- Fast CI/CD

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build ForgeOS

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # Cache downloaded packages
      - uses: actions/cache@v3
        with:
          path: packages/downloads
          key: forgeos-packages-${{ hashFiles('packages/checksums.mk') }}
      
      # Download packages (only if cache miss)
      - name: Download packages
        run: make download-packages
      
      # Build offline (fast!)
      - name: Build ForgeOS
        run: make all PROFILE=core-min ARCH=aarch64
```

### Benefits for CI/CD

✅ **Package Caching**: Downloads cached between runs  
✅ **Faster Builds**: No download time during builds  
✅ **Reliable**: No network-related failures  
✅ **Predictable**: Consistent build times  
✅ **Cost Effective**: Reduced network usage  

## Troubleshooting

### Download Failures

**Problem**: Package download fails

```bash
[✗] Failed to download after 3 attempts: package.tar.gz
```

**Solutions:**
1. Check internet connectivity
2. Verify URL accessibility
3. Check firewall/proxy settings
4. Manually download and place in `packages/downloads/`

### Checksum Mismatch

**Problem**: Checksum verification fails

```bash
[✗] Checksum mismatch for package.tar.gz
  Expected: abc123...
  Actual:   def456...
```

**Solutions:**
1. Re-download the package (remove and retry)
2. Update checksum in `packages/checksums.mk`
3. Verify upstream package hasn't changed

### Missing Packages

**Problem**: Package not found in downloads

```bash
Error: Package not found: packages/downloads/package.tar.gz
```

**Solutions:**
1. Run `make download-packages` first
2. Check if package URL is correct
3. Manually download if automated download fails

### Disk Space

**Problem**: Not enough disk space

**Solutions:**
1. Check available space: `df -h`
2. Clean old downloads: `make clean-downloads`
3. Download only required packages (modify script)

## Future Enhancements

### Planned Features (v0.2+)

- [ ] Parallel downloads for faster initial download
- [ ] Mirror support for redundancy
- [ ] Differential updates (only download changed packages)
- [ ] Package metadata (size, date, source URL)
- [ ] Web UI for package management
- [ ] Automatic checksum updates
- [ ] CDN integration for faster downloads
- [ ] Resume broken downloads

### Community Contributions

We welcome contributions to enhance the offline package system:

- Additional package sources
- Mirror infrastructure
- Download optimization
- Better error handling
- Documentation improvements

## References

- [THE-118 Linear Issue](https://linear.app/theedgeworks/issue/THE-118)
- [Package System Documentation](package-system.md)
- [Build System Documentation](build-system.md)
- [Security Guidelines](hardening.md)

## Changelog

### v1.0.0 (2025-10-03)
- Initial implementation
- 15 core packages supported
- SHA256 checksum verification
- Retry logic with 3 attempts
- Makefile integration
- Comprehensive documentation

---

**ForgeOS Offline Package System** - Build Anywhere, Anytime 🌐➡️📦

