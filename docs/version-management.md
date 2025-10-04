# ForgeOS Centralized Version Management

## Overview

ForgeOS implements a centralized version management system to eliminate version duplication and ensure consistency across all components. This system provides a single source of truth for all version information.

## Problem Solved

Previously, version information was scattered across multiple files:
- Individual APKBUILD files had hardcoded versions
- Multiple `versions.mk` files in different directories
- Duplicate version information in shell and Makefile formats
- Inconsistent version management across components

## Solution

### Centralized Version Files

#### 1. Root Level Version Files
- **`versions.mk`** - Makefile-compatible version definitions
- **`versions.sh`** - Shell-compatible version definitions
- **`checksums.mk`** - Makefile-compatible SHA256 checksums
- **`checksums.sh`** - Shell-compatible SHA256 checksums

#### 2. Version Categories

##### Toolchain Versions
```makefile
BINUTILS_VERSION := 2.42
GCC_VERSION := 15.2.0
MUSL_VERSION := 1.2.4
GLIBC_VERSION := 2.38
LINUX_HEADERS_VERSION := 6.6
MUSL_CROSS_MAKE_VERSION := 0.9.9
CROSSTOOL_NG_VERSION := 1.25.0
```

##### Kernel Versions
```makefile
LINUX_VERSION := 6.6.0
LINUX_VERSION_MAJOR := 6
LINUX_VERSION_MINOR := 6
LINUX_VERSION_PATCH := 0
```

##### Userland Versions
```makefile
BUSYBOX_VERSION := 1.36.1
BUSYBOX_VERSION_MAJOR := 1
BUSYBOX_VERSION_MINOR := 36
BUSYBOX_VERSION_PATCH := 1
```

##### Package System Versions
```makefile
APK_TOOLS_VERSION := 2.14.0
IPROUTE2_VERSION := 6.1.0
CHRONY_VERSION := 4.3
DROPBEAR_VERSION := 2022.83
NFTABLES_VERSION := 1.0.7
CA_CERTIFICATES_VERSION := 20230311
```

### Updated APKBUILD Files

All APKBUILD files now use centralized version variables:

```bash
# Before (hardcoded)
pkgver="6.1.0"

# After (centralized)
pkgver="${IPROUTE2_VERSION}"
```

### Updated Build System

All Makefiles now reference the centralized versions:

```makefile
# Before (local versions)
include $(SCRIPT_DIR)/../versions.mk

# After (centralized versions)
include $(PROJECT_ROOT)/versions.mk
```

## Benefits

✅ **Single Source of Truth** - All versions defined in one place  
✅ **Consistency** - No version mismatches between components  
✅ **Maintainability** - Easy to update versions across the entire system  
✅ **Automation** - Scripts can automatically use latest versions  
✅ **Verification** - Centralized checksums for integrity  
✅ **Documentation** - Clear version tracking and history  

## Usage

### For Makefiles
```makefile
include $(PROJECT_ROOT)/versions.mk
# Now use $(LINUX_VERSION), $(BUSYBOX_VERSION), etc.
```

### For Shell Scripts
```bash
source "$PROJECT_ROOT/versions.sh"
# Now use $LINUX_VERSION, $BUSYBOX_VERSION, etc.
```

### For APKBUILD Files
```bash
pkgver="${PACKAGE_VERSION}"
# Version is automatically sourced from centralized system
```

## Version Update Process

1. **Update Central Versions**: Modify `versions.mk` and `versions.sh`
2. **Update Checksums**: Modify `checksums.mk` and `checksums.sh` with actual SHA256 values
3. **Test Builds**: Verify all components build with new versions
4. **Update Documentation**: Update this document with version changes

## File Structure

```
forgeos/
├── versions.mk          # Centralized Makefile versions
├── versions.sh          # Centralized shell versions
├── checksums.mk         # Centralized Makefile checksums
├── checksums.sh         # Centralized shell checksums
├── toolchains/
│   └── musl/Makefile    # Uses centralized versions
├── kernel/
│   └── Makefile         # Uses centralized versions
├── userland/
│   └── busybox/Makefile # Uses centralized versions
├── packages/
│   └── sources/
│       ├── iproute2/APKBUILD    # Uses centralized versions
│       ├── chrony/APKBUILD      # Uses centralized versions
│       ├── dropbear/APKBUILD    # Uses centralized versions
│       ├── nftables/APKBUILD    # Uses centralized versions
│       └── ca-certificates/APKBUILD # Uses centralized versions
└── scripts/
    └── download_packages.sh     # Uses centralized versions
```

## Migration Notes

### Removed Files
- `toolchains/versions.mk` → Use `versions.mk`
- `kernel/versions.mk` → Use `versions.mk`
- `userland/versions.mk` → Use `versions.mk`
- `packages/versions.mk` → Use `versions.mk`
- `packages/versions.sh` → Use `versions.sh`
- `packages/checksums.mk` → Use `checksums.mk`
- `packages/checksums.sh` → Use `checksums.sh`

### Updated References
- All Makefiles now include `$(PROJECT_ROOT)/versions.mk`
- All shell scripts now source `$PROJECT_ROOT/versions.sh`
- All APKBUILD files use `${PACKAGE_VERSION}` variables
- Download script uses centralized versions and checksums

## Future Enhancements

- [ ] Automated version checking against upstream releases
- [ ] Version compatibility matrix
- [ ] Automated checksum verification
- [ ] Version rollback capabilities
- [ ] Integration with CI/CD for version updates
