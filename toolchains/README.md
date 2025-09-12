# ForgeOS Toolchains

This directory contains the cross-compilation toolchain infrastructure for ForgeOS.

## Overview

ForgeOS supports two toolchain tracks:

- **musl (default)**: Lightweight, static linking, minimal dependencies
- **glibc (optional)**: Full compatibility, dynamic linking support

## Quick Start

### Build musl toolchain (recommended)

```bash
# Build musl toolchain for aarch64
make -C toolchains/musl ARCH=aarch64

# Or use the main Makefile
make toolchain TOOLCHAIN=musl ARCH=aarch64
```

### Build glibc toolchain (optional)

```bash
# Build glibc toolchain for aarch64
make -C toolchains/gnu ARCH=aarch64

# Or use the main Makefile
make toolchain TOOLCHAIN=gnu ARCH=aarch64
```

## Toolchain Configuration

### Version Management

All toolchain versions are pinned in `versions.mk`:

- **binutils**: 2.42
- **GCC**: 13.2.0
- **musl**: 1.2.4
- **glibc**: 2.38
- **Linux headers**: 6.6

### Environment Setup

Load the toolchain environment in your scripts:

```bash
# For musl toolchain
source toolchains/env.musl

# For glibc toolchain
source toolchains/env.gnu
```

This sets up:
- `CROSS_COMPILE` prefix
- `CC`, `CXX`, `AR`, `STRIP` variables
- `PATH` with toolchain binaries
- Build flags for reproducible builds

## Architecture Support

### Currently Supported

- **aarch64**: Primary target for edge devices
- **x86_64**: Gateway and server targets (planned)

### Adding New Architectures

1. Update `versions.mk` if needed
2. Test toolchain build: `make -C toolchains/musl ARCH=<arch>`
3. Update environment scripts if needed
4. Test cross-compilation

## Build Process

### musl Toolchain

The musl toolchain uses [musl-cross-make](https://github.com/richfelker/musl-cross-make):

1. **Download**: Downloads musl-cross-make source
2. **Configure**: Sets up build configuration
3. **Build**: Compiles toolchain components
4. **Install**: Installs to `toolchains/output/`
5. **Verify**: Tests toolchain functionality

### glibc Toolchain

The glibc toolchain uses system-provided cross-compilers:

1. **Detect**: Checks for system cross-compiler
2. **Link**: Creates symlinks in output directory
3. **Verify**: Tests toolchain functionality

## Output Structure

```
toolchains/output/
├── aarch64-linux-musl/          # musl toolchain
│   ├── bin/                     # Cross-compilation tools
│   ├── lib/                     # Libraries
│   ├── include/                 # Headers
│   └── sysroot/                 # System root
└── aarch64-linux-gnu/           # glibc toolchain
    ├── bin/                     # Cross-compilation tools
    └── ...
```

## Cross-Compilation Example

```bash
# Load musl environment
source toolchains/env.musl

# Compile a simple C program
echo 'int main(){return 0;}' > hello.c
aarch64-linux-musl-gcc -static -o hello hello.c

# Verify binary
file hello
# Output: hello: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped
```

## Build Flags

### Reproducible Builds

All toolchains use deterministic build flags:

- `SOURCE_DATE_EPOCH` for consistent timestamps
- `--build-id=sha1` for deterministic build IDs
- Static linking for musl toolchain
- Optimized for size (`-Os`)

### Security

- Stack protection disabled for minimal size
- Unwind tables disabled
- Static linking preferred for musl

## Troubleshooting

### Common Issues

#### Build Failures

```bash
# Check dependencies
make -C toolchains/musl config

# Clean and retry
make -C toolchains/musl clean
make -C toolchains/musl
```

#### Missing Cross-Compiler

```bash
# On macOS
brew install gcc-aarch64-elf

# On Ubuntu
sudo apt-get install gcc-aarch64-linux-gnu
```

#### Permission Issues

```bash
# Fix permissions
chmod +x toolchains/env.*
```

### Debugging

1. **Check configuration**: `make -C toolchains/musl config`
2. **Verify environment**: `source toolchains/env.musl && env | grep CROSS`
3. **Test compilation**: Try cross-compiling a simple program
4. **Check paths**: Verify toolchain binaries are in PATH

## Performance

### Build Time

- **musl toolchain**: ~30-60 minutes (first build)
- **glibc toolchain**: ~5 minutes (uses system compiler)
- **Subsequent builds**: Much faster (cached)

### Optimization

- Use parallel builds: `make -j$(nproc)`
- Cache toolchain builds (they're expensive)
- Use SSD storage for better I/O performance

## Security Considerations

- All toolchains use pinned versions
- Build process is deterministic
- No network access during compilation
- Signed toolchain binaries (planned)

## Integration

### With ForgeOS Build System

The toolchains integrate with the main ForgeOS build system:

```bash
# Build everything with musl toolchain
make TOOLCHAIN=musl

# Build specific component
make kernel TOOLCHAIN=musl
```

### With CI/CD

Toolchains are cached in CI/CD pipelines:

- Build once, reuse many times
- Version-pinned for reproducibility
- Signed for security verification

## Future Enhancements

- [ ] LLVM/Clang toolchain support
- [ ] Custom toolchain configurations
- [ ] Toolchain signing and verification
- [ ] Automated toolchain testing
- [ ] Multi-architecture builds

## References

- [musl-cross-make](https://github.com/richfelker/musl-cross-make)
- [crosstool-ng](https://crosstool-ng.github.io/)
- [GCC Cross-Compiler](https://gcc.gnu.org/onlinedocs/gcc/Cross-Compilation.html)
- [ForgeOS Architecture](docs/architecture.md)
