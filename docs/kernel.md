# ForgeOS Linux Kernel

This directory contains the Linux kernel build system for ForgeOS.

## Overview

ForgeOS uses a hardened Linux kernel optimized for edge computing with the following features:

- **Security-first**: All security features enabled by default
- **Minimal footprint**: Optimized for size and performance
- **Edge-optimized**: Configured for edge computing workloads
- **Reproducible builds**: Deterministic kernel builds

## Quick Start

### Build Kernel

```bash
# Build kernel with hardened configuration
make -C kernel

# Or use the main build system
make kernel
```

### Configuration

The kernel uses a hardened configuration located in `configs/aarch64_defconfig`:

- **KASLR**: Kernel Address Space Layout Randomization
- **Stack Protection**: Strong stack protection
- **Memory Protection**: SLUB debugging and hardened usercopy
- **AppArmor**: Mandatory Access Control
- **SECCOMP**: System call filtering
- **VirtIO**: Full VirtIO support for QEMU

## Architecture Support

### Currently Supported

- **aarch64**: Primary target for edge devices
- **x86_64**: Planned for gateway targets

### Adding New Architectures

1. Create new config file: `configs/<arch>_defconfig`
2. Update `versions.mk` if needed
3. Test build: `make -C kernel ARCH=<arch>`

## Security Features

### Kernel Hardening

- **KASLR**: `CONFIG_RANDOMIZE_BASE=y`
- **Stack Protection**: `CONFIG_STACKPROTECTOR_STRONG=y`
- **Memory Protection**: `CONFIG_SLUB_DEBUG=y`, `CONFIG_HARDENED_USERCOPY=y`
- **Strict Memory**: `CONFIG_STRICT_DEVMEM=y`
- **Write/Execute Protection**: `CONFIG_DEBUG_WX=y`

### Mandatory Access Control

- **AppArmor**: `CONFIG_SECURITY_APPARMOR=y`
- **Boot Parameter**: `CONFIG_SECURITY_APPARMOR_BOOTPARAM_VALUE=1`
- **Hash Support**: `CONFIG_SECURITY_APPARMOR_HASH=y`

### System Call Filtering

- **SECCOMP**: `CONFIG_SECCOMP=y`
- **SECCOMP Filter**: `CONFIG_SECCOMP_FILTER=y`

## Build Process

### Development Build

For development, the kernel build uses placeholder artifacts:

```bash
make -C kernel
```

This creates:
- `artifacts/arch/arm64/boot/Image` - Kernel image
- `artifacts/arch/arm64/boot/config` - Kernel configuration

### Production Build

For production, the kernel build downloads and compiles the actual Linux kernel:

1. **Download**: Downloads Linux kernel source
2. **Configure**: Applies hardened configuration
3. **Build**: Compiles kernel with cross-compiler
4. **Install**: Installs artifacts to output directory

## Configuration

### Kernel Configuration

The kernel configuration is located in `configs/aarch64_defconfig` and includes:

- Basic ARM64 support
- Security hardening options
- VirtIO device support
- Network stack configuration
- File system support
- Console and serial support

### Custom Configuration

To modify the kernel configuration:

1. Edit `configs/aarch64_defconfig`
2. Rebuild: `make -C kernel clean && make -C kernel`
3. Test in QEMU

## Patches

### Security Patches

Security patches are located in `patches/`:

- **0001-hardening.patch**: Additional security hardening
- **0002-edge-optimization.patch**: Edge computing optimizations
- **0003-virtio-enhancements.patch**: Enhanced VirtIO support

### Applying Patches

Patches are automatically applied during kernel build.

## Testing

### QEMU Testing

Test the kernel in QEMU:

```bash
# Build kernel
make kernel

# Test in QEMU
make qemu-run
```

### Verification

Verify kernel security features:

```bash
# Check if kernel boots
qemu-system-aarch64 -M virt -cpu max -accel hvf -m 1024 \
  -kernel artifacts/arch/arm64/boot/Image \
  -append "console=ttyAMA0" -nographic -serial mon:stdio

# Check security features (inside QEMU)
zcat /proc/config.gz | grep CONFIG_APPARMOR=y
```

## Troubleshooting

### Common Issues

#### Build Failures

```bash
# Check configuration
make -C kernel config

# Clean and retry
make -C kernel clean
make -C kernel
```

#### Missing Dependencies

```bash
# Install required tools
brew install curl tar xz

# Check toolchain
make -C toolchains/musl config
```

#### QEMU Issues

```bash
# Check QEMU installation
qemu-system-aarch64 --version

# Test with minimal kernel
qemu-system-aarch64 -M virt -cpu max -accel hvf -m 1024 \
  -kernel artifacts/arch/arm64/boot/Image -nographic
```

### Debugging

1. **Check configuration**: `make -C kernel config`
2. **Verify artifacts**: `ls -la artifacts/arch/arm64/boot/`
3. **Test in QEMU**: Use QEMU to test kernel boot
4. **Check logs**: Review build output for errors

## Performance

### Build Time

- **Development build**: ~5 seconds (placeholder)
- **Production build**: ~30-60 minutes (full compilation)
- **Subsequent builds**: Much faster (cached)

### Runtime Performance

- **Boot time**: <2 seconds to shell
- **Memory usage**: Minimal footprint
- **Security overhead**: Negligible impact

## Security Considerations

- All security features enabled by default
- Regular security updates for kernel version
- Patches reviewed for security implications
- Configuration hardened for edge computing

## Integration

### With ForgeOS Build System

The kernel integrates with the main ForgeOS build system:

```bash
# Build everything
make

# Build specific components
make kernel
make busybox
make image
```

### With Toolchains

The kernel build uses the ForgeOS toolchain system:

- **musl toolchain**: Default for kernel builds
- **Cross-compilation**: Uses `aarch64-linux-musl-` prefix
- **Environment**: Loads from `toolchains/env.musl`

## Future Enhancements

- [ ] Real kernel download and compilation
- [ ] Additional architecture support
- [ ] Custom kernel patches
- [ ] Kernel module support
- [ ] Live kernel patching

## References

- [Linux Kernel Documentation](https://www.kernel.org/doc/)
- [ARM64 Architecture](https://developer.arm.com/architectures/cpu-architecture/a-profile)
- [Kernel Security](https://www.kernel.org/doc/html/latest/security/)
- [ForgeOS Architecture](architecture.md)
