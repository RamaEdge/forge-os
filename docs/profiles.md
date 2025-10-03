# ForgeOS Profiles System

ForgeOS uses a **modular profile system** to create different system configurations for various use cases. Each profile is a complete system configuration that can be built independently.

## Profile Philosophy

Profiles allow you to choose the right system configuration for your specific needs:
- **Minimal footprint**: Only include what you need
- **Security-first**: Each profile is hardened by default
- **Edge-optimized**: Configured for edge computing workloads
- **Reproducible**: Deterministic profile builds

## Profile Structure

Each profile in `profiles/` follows this structure:

```
profiles/PROFILE_NAME/
├─ overlay/           # Filesystem overlay (configs, init scripts)
│  ├─ etc/           # Configuration files
│  ├─ usr/           # User binaries and libraries
│  └─ var/           # Variable data templates
├─ packages.txt      # Package list for this profile
└─ README.md         # Profile documentation (planned)
```

## Core Profiles

### core-min

**Purpose**: Minimal system for embedded/headless devices

- **Init**: BusyBox init with mdev
- **Networking**: Loopback only (no external network access)
- **Access**: Serial console only (ttyAMA0)
- **Services**: Minimal logging, basic system services
- **Use case**: IoT sensors, simple embedded devices, air-gapped systems

**Configuration**:
- `/etc/inittab`: BusyBox init with serial console
- `/etc/init.d/rcS`: Minimal startup script
- `/etc/motd`: core-min specific welcome message
- No network services or external access

### core-net

**Purpose**: Network-enabled minimal system

- **Init**: BusyBox init with enhanced networking
- **Networking**: DHCP client, firewall, time sync
- **Access**: Serial console + SSH (when configured)
- **Services**: Network services, log shipping, basic monitoring
- **Use case**: Network gateways, remote devices, edge computing nodes

**Configuration**:
- `/etc/inittab`: BusyBox init with network services
- `/etc/init.d/rcS`: Network-enabled startup script
- `/etc/motd`: core-net specific welcome message
- Network configuration and firewall rules

### service-sd (Planned)

**Purpose**: Full systemd-based system

- **Init**: systemd with full service management
- **Networking**: systemd-networkd, systemd-resolved
- **Access**: SSH, serial console
- **Services**: journald, systemd timers, cgroups v2
- **Use case**: Servers, complex service deployments

## Profile Development Guidelines

### Overlay Files

- **Configuration files**: Place in `overlay/etc/`
- **Init scripts**: Place in `overlay/etc/init.d/`
- **User binaries**: Place in `overlay/usr/local/bin/`
- **Service data**: Place in `overlay/var/`

### Package Management

- **Base packages**: Inherit from base system (BusyBox, kernel)
- **Profile packages**: List in `packages.txt`
- **Dependencies**: Explicitly list all required packages
- **Version pinning**: Pin package versions for reproducibility

### Configuration Templates

- **Environment variables**: Use `@PROFILE@` placeholders
- **Service configs**: Template with profile-specific settings
- **Network configs**: Profile-appropriate network settings
- **Security policies**: Profile-specific hardening

## Profile Build Process

### Build Integration

1. **Base system**: Build kernel, BusyBox, toolchain
2. **Profile selection**: Choose profile via `PROFILE=core-min`
3. **Overlay application**: Apply profile overlay to base
4. **Package installation**: Install profile-specific packages
5. **Configuration**: Apply profile-specific configurations
6. **Finalization**: Create final rootfs and images

### Makefile Integration

```makefile
# Profile-specific builds
build-$(PROFILE): toolchain kernel busybox
	$(MAKE) -C profiles/$(PROFILE) build

# Default profile
PROFILE ?= core-min
```

## Using Profiles

### Building with a Profile

```bash
# Build with core-min profile (default)
make PROFILE=core-min

# Build with core-net profile
make PROFILE=core-net

# Build with custom profile
make PROFILE=my-custom-profile
```

### Applying Profiles

```bash
# Apply profile to existing rootfs
./scripts/apply_profile.sh core-min /path/to/rootfs

# Apply profile during build
make rootfs PROFILE=core-net
```

### Profile Switching

```bash
# Switch profile on existing system
./scripts/apply_profile.sh core-net /mnt/rootfs
```

## Profile Customization

### Adding New Profiles

1. **Create directory**: `profiles/NEW_PROFILE/`
2. **Define overlay**: Create `overlay/` with configs
3. **List packages**: Create `packages.txt`
4. **Document**: Add `README.md` with usage instructions
5. **Test**: Build and test profile in QEMU
6. **Integrate**: Add to CI/CD matrix

### Profile Inheritance

- **Base overlay**: All profiles inherit from `userland/overlay-base/`
- **Profile overlay**: Profile-specific files override base
- **Package inheritance**: Profiles can extend base package lists
- **Configuration inheritance**: Profile configs extend base configs

## Profile Testing

### QEMU Testing

```bash
# Test core-min profile
make qemu-run PROFILE=core-min

# Test core-net profile
make qemu-run PROFILE=core-net
```

### Verification

- **Boot testing**: Verify profile boots in QEMU
- **Service testing**: Verify all services start correctly
- **Network testing**: Test network configuration (for core-net)
- **Security testing**: Verify security policies work

## Profile Best Practices

### Design Principles

- **Single responsibility**: Each profile has one clear purpose
- **Minimal dependencies**: Only include what's needed
- **Secure defaults**: Security-first configuration
- **Reproducible**: Deterministic profile builds

### Implementation Guidelines

- **Modular design**: Reusable components across profiles
- **Clear interfaces**: Well-defined profile interfaces
- **Error handling**: Robust error handling in profile scripts
- **Logging**: Comprehensive logging for debugging

## Troubleshooting

### Common Issues

#### Profile Not Found
```bash
# Check available profiles
ls -la profiles/

# Verify profile structure
ls -la profiles/core-min/
```

#### Profile Application Fails
```bash
# Check profile overlay
ls -la profiles/core-min/overlay/

# Verify rootfs directory
ls -la /path/to/rootfs/
```

#### Services Not Starting
```bash
# Check init scripts
cat profiles/core-min/overlay/etc/init.d/rcS

# Verify permissions
ls -la /path/to/rootfs/etc/init.d/
```

## Future Enhancements

- [ ] service-sd profile with systemd
- [ ] iot-field profile for industrial IoT
- [ ] ai-infer profile for AI workloads
- [ ] Custom profile builder
- [ ] Profile validation tools
- [ ] Profile migration tools

## References

- [ForgeOS Architecture](architecture.md)
- [Build System](build-on-macos.md)
- [Userland Base](../userland/README.md)
- [Security Guidelines](security.md)
