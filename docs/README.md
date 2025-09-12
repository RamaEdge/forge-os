# ForgeOS Documentation

This directory contains all documentation for the ForgeOS project. All documentation is centralized here to provide a single source of truth.

## Documentation Structure

### Core Documentation
- **[architecture.md](architecture.md)** - Complete system architecture overview
- **[implementation_plan.md](implementation_plan.md)** - Detailed development roadmap and milestones
- **[build-on-macos.md](build-on-macos.md)** - Build instructions for macOS development

### Component Documentation
- **[toolchains.md](toolchains.md)** - Cross-compilation toolchain system
- **[kernel.md](kernel.md)** - Linux kernel build system and configuration
- **[kernel-patches.md](kernel-patches.md)** - Security hardening patches

### Planned Documentation
- **[profiles.md](profiles.md)** - Profile system documentation (planned)
- **[security.md](security.md)** - Security guidelines and hardening (planned)
- **[observability.md](observability.md)** - Logging and monitoring (planned)
- **[device-management.md](device-management.md)** - Device management guide (planned)
- **[troubleshooting.md](troubleshooting.md)** - Common issues and solutions (planned)

## Documentation Standards

### Centralized Approach
- **All documentation** must be placed in this `docs/` folder
- **No scattered docs** - avoid README files in subdirectories
- **Single source** - one authoritative location for all documentation
- **Cross-references** - use relative links within the docs folder

### Writing Guidelines
- **Clear structure** - use consistent headings and organization
- **Practical examples** - include copy-paste-friendly commands
- **Up-to-date** - keep documentation current with code changes
- **Cross-linked** - reference related documentation sections

### File Naming
- Use lowercase with hyphens: `build-on-macos.md`
- Be descriptive: `kernel-patches.md` not `patches.md`
- Group related content: `device-management.md` not `device.md`

## Quick Navigation

### For New Contributors
1. Start with [architecture.md](architecture.md) for system overview
2. Read [implementation_plan.md](implementation_plan.md) for development roadmap
3. Follow [build-on-macos.md](build-on-macos.md) for setup instructions

### For Developers
- [toolchains.md](toolchains.md) - Cross-compilation setup
- [kernel.md](kernel.md) - Kernel development
- [kernel-patches.md](kernel-patches.md) - Security patches

### For Users
- [build-on-macos.md](build-on-macos.md) - Building ForgeOS
- [architecture.md](architecture.md) - Understanding the system

## Contributing to Documentation

### Adding New Documentation
1. Create new `.md` files in this `docs/` folder
2. Use descriptive filenames with hyphens
3. Add cross-references to related documentation
4. Update this README.md to include new files

### Updating Existing Documentation
1. Keep content current with code changes
2. Update cross-references when moving content
3. Maintain consistent formatting and structure
4. Test all links and examples

### Documentation Review
- All documentation changes should be reviewed
- Ensure examples work and are tested
- Verify cross-references are correct
- Check for typos and clarity

## External References

### Project Links
- [Main Repository](../README.md) - Project overview and quick start
- [LICENSE](../LICENSE) - GNU General Public License v3.0

### Related Projects
- [musl-cross-make](https://github.com/richfelker/musl-cross-make) - Cross-compilation toolchain
- [Linux Kernel](https://www.kernel.org/) - Linux kernel documentation
- [QEMU](https://www.qemu.org/) - Virtualization platform

## Maintenance

This documentation is maintained as part of the ForgeOS project. When making changes to the codebase, ensure that relevant documentation is updated accordingly.

For questions about documentation or suggestions for improvements, please create an issue in the project repository.
