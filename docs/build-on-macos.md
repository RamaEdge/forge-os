# Building ForgeOS on macOS

This guide covers building ForgeOS on Apple Silicon (ARM64) macOS systems.

## Prerequisites

### Required Software

- **macOS**: 12.0 (Monterey) or later
- **Xcode Command Line Tools**: `xcode-select --install`
- **Homebrew**: [Installation guide](https://brew.sh/)
- **QEMU**: `brew install qemu`
- **Git**: `brew install git`
- **Make**: Usually included with Xcode Command Line Tools

### Optional Software

- **Lima VM**: For Linux-specific tools (mkfs.ext4, losetup)
  ```bash
  brew install lima
  ```

## Initial Setup

### 1. Clone the Repository

```bash
git clone <forgeos-repo-url>
cd forge-os
```

### 2. Initialize Submodules

```bash
git submodule update --init --recursive
```

### 3. Verify Prerequisites

```bash
# Check QEMU installation
qemu-system-aarch64 --version

# Check Git
git --version

# Check Make
make --version
```

## Building ForgeOS

### Quick Start

```bash
# Build everything
make

# Or build step by step
make toolchain
make kernel
make busybox
make rootfs
make initramfs
make image
```

### Available Make Targets

- `toolchain` - Build cross-compilation toolchains
- `kernel` - Build Linux kernel
- `busybox` - Build BusyBox userland
- `rootfs` - Create root filesystem
- `initramfs` - Generate initramfs
- `image` - Create final disk images
- `qemu-run` - Launch QEMU for testing
- `sign` - Sign all artifacts
- `release` - Create release bundles
- `clean` - Clean build artifacts
- `help` - Show available targets

### Configuration Options

You can customize the build using environment variables:

```bash
# Set profile (default: core-min)
export PROFILE=core-net

# Set architecture (default: aarch64)
export ARCH=aarch64

# Set toolchain (default: musl)
export TOOLCHAIN=musl

# Build with custom settings
make PROFILE=core-net ARCH=aarch64
```

## Testing with QEMU

### Basic QEMU Test

```bash
# Build and test
make qemu-run
```

### Manual QEMU Launch

```bash
# Launch QEMU manually
qemu-system-aarch64 \
  -M virt \
  -cpu max \
  -accel hvf \
  -m 1024 \
  -kernel artifacts/arch/arm64/boot/Image \
  -initrd artifacts/initramfs.gz \
  -append "console=ttyAMA0" \
  -nographic \
  -serial mon:stdio
```

### QEMU with Disk Image

```bash
# Launch with persistent disk
qemu-system-aarch64 \
  -M virt \
  -cpu max \
  -accel hvf \
  -m 1024 \
  -kernel artifacts/arch/arm64/boot/Image \
  -drive file=artifacts/root.img,format=raw,if=virtio \
  -append "console=ttyAMA0 root=/dev/vda" \
  -nographic \
  -serial mon:stdio
```

## Development Workflow

### 1. Development Setup

```bash
# Set up development environment
make dev-setup
```

### 2. Iterative Development

```bash
# Clean previous build
make clean

# Build specific component
make kernel

# Test in QEMU
make qemu-run
```

### 3. Debugging

```bash
# Enable verbose output
make V=1 kernel

# Check build configuration
make config

# Clean and rebuild
make clean && make
```

## Troubleshooting

### Common Issues

#### QEMU Not Found
```bash
# Install QEMU via Homebrew
brew install qemu

# Verify installation
which qemu-system-aarch64
```

#### Permission Issues
```bash
# Fix script permissions
chmod +x scripts/*.sh
```

#### Build Failures
```bash
# Clean and retry
make clean
make

# Check for missing dependencies
make help
```

#### QEMU Performance Issues
```bash
# Ensure HVF acceleration is available
sysctl kern.hv_support

# Use fewer CPU cores if needed
export QEMU_CPUS=2
```

### Debugging Tips

1. **Check Build Logs**: Look for error messages in the build output
2. **Verify Artifacts**: Ensure required files are created in `artifacts/`
3. **Test Components**: Build and test individual components
4. **Check Dependencies**: Ensure all prerequisites are installed

### Getting Help

- Check the [Architecture Documentation](architecture.md)
- Review the [Implementation Plan](implementation_plan.md)
- Search existing issues in the project repository
- Create a new issue with detailed error information

## Performance Optimization

### Build Performance

- Use parallel builds: `make -j$(nproc)`
- Cache toolchain builds (they're expensive)
- Use SSD storage for better I/O performance

### QEMU Performance

- Use HVF acceleration (default on Apple Silicon)
- Allocate sufficient memory (default: 1GB)
- Use virtio devices for better performance

## Security Considerations

- All builds use deterministic timestamps (`SOURCE_DATE_EPOCH`)
- Artifacts are signed with cryptographic signatures
- Build process follows security-first principles
- Regular security updates for dependencies

## Next Steps

After successfully building ForgeOS:

1. **Test Profiles**: Try different profiles (`core-min`, `core-net`)
2. **Customize Builds**: Modify configurations for your needs
3. **Contribute**: Submit improvements and bug fixes
4. **Deploy**: Use ForgeOS in your edge computing projects

For more information, see the [Architecture Documentation](architecture.md) and [Implementation Plan](implementation_plan.md).
