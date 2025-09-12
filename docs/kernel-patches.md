# ForgeOS Kernel Patches

This directory contains security hardening patches for the Linux kernel.

## Patch Overview

### Security Hardening Patches

- **0001-hardening.patch**: Additional security hardening options
- **0002-edge-optimization.patch**: Optimizations for edge computing
- **0003-virtio-enhancements.patch**: Enhanced VirtIO support for QEMU

## Applying Patches

Patches are automatically applied during kernel build:

```bash
# Build kernel with patches
make -C kernel

# Or use the main build system
make kernel
```

## Patch Development

When creating new patches:

1. **Test thoroughly**: Ensure patches don't break functionality
2. **Document changes**: Include clear descriptions
3. **Version compatibility**: Test with target kernel version
4. **Security review**: Review all security-related changes

## Patch Format

All patches follow standard kernel patch format:

```
From: ForgeOS Security Team <security@forgeos.org>
Subject: [PATCH] Description of changes

Detailed description of the patch...

Signed-off-by: ForgeOS Security Team <security@forgeos.org>
---
```

## Security Considerations

- All patches are reviewed for security implications
- Patches are tested in QEMU before deployment
- Changes are documented and tracked
- Rollback procedures are available
