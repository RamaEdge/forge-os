# ForgeOS

**Lightweight Linux forged for the edge**

ForgeOS is a minimal, secure, and reproducible Linux distribution designed for edge computing environments. Built with security-first principles, it provides fast boot times, deterministic builds, and modular profiles for different use cases.

## Quick Start

```bash
# Clone and build
git clone <forgeos-repo>
cd forge-os
make

# Test in QEMU
make qemu-run
```

## Documentation

All documentation is centralized in the [`docs/`](docs/) folder. See the [Documentation Index](docs/README.md) for a complete overview.

**Quick Links:**
- **[Architecture](docs/architecture.md)** - Complete system architecture overview
- **[Implementation Plan](docs/implementation_plan.md)** - Detailed development roadmap
- **[Build on macOS](docs/build-on-macos.md)** - Build instructions for macOS
- **[Toolchains](docs/toolchains.md)** - Cross-compilation toolchain system
- **[Kernel](docs/kernel.md)** - Linux kernel build system

## Key Features

- **Security-first**: Hardened kernel, AppArmor, seccomp, KASLR
- **Fast boot**: <2s to shell on QEMU, <10s to network on hardware
- **Reproducible**: Deterministic builds with pinned versions
- **Modular**: Profile-based system for different use cases
- **Edge-optimized**: Minimal footprint, offline-capable

## Profiles

- **core-min**: Minimal system for embedded devices
- **core-net**: Network-enabled minimal system
- **service-sd**: Full systemd-based system
- **iot-field**: Industrial IoT gateway
- **ai-infer**: AI inference workloads

## Target Environments

- **Build host**: Apple Silicon macOS with QEMU/HVF
- **Primary targets**: aarch64 edge devices (Raspberry Pi 5, NXP i.MX8, Ampere, Jetson)
- **Boot modes**: QEMU `-M virt`, U-Boot+EFI, GRUB/EFI

## Development

See [Build on macOS](docs/build-on-macos.md) for detailed setup instructions.

## License

GNU General Public License v3.0 - see [LICENSE](LICENSE) for details.