# ForgeOS Security Hardening Guide

**Implementation**: THE-52 (Security Baseline)  
**Status**: Complete  
**Last Updated**: 2025-10-03

## Overview

ForgeOS is **secure by default**, implementing defense-in-depth with multiple layers of security controls. This document describes the security hardening measures implemented across the system.

## Table of Contents

- [Kernel Security](#kernel-security)
- [Mandatory Access Control (AppArmor)](#mandatory-access-control-apparmor)
- [Network Security (nftables)](#network-security-nftables)
- [Filesystem Security](#filesystem-security)
- [User Separation](#user-separation)
- [Package Signing](#package-signing)
- [Verification](#verification)

## Kernel Security

### Kernel Configuration

All security features are enabled in [`kernel/configs/aarch64_defconfig`](../kernel/configs/aarch64_defconfig):

#### Address Space Layout Randomization (KASLR)
```
CONFIG_RANDOMIZE_BASE=y
CONFIG_RANDOMIZE_MEMORY=y
CONFIG_ARCH_MMAP_RND_BITS=18
CONFIG_ARCH_MMAP_RND_COMPAT_BITS=11
```

**Purpose**: Randomizes kernel and process memory addresses to prevent exploitation.

#### Stack Protection
```
CONFIG_STACKPROTECTOR=y
CONFIG_STACKPROTECTOR_STRONG=y
CONFIG_STACK_VALIDATION=y
```

**Purpose**: Detects and prevents stack buffer overflows.

#### Memory Hardening
```
CONFIG_SLUB_DEBUG=y
CONFIG_HARDENED_USERCOPY=y
CONFIG_FORTIFY_SOURCE=y
CONFIG_PAGE_TABLE_ISOLATION=y
```

**Purpose**: Hardens memory allocation and protects against use-after-free and other memory exploits.

#### System Call Filtering (SECCOMP)
```
CONFIG_SECCOMP=y
CONFIG_SECCOMP_FILTER=y
```

**Purpose**: Allows processes to restrict their own system call privileges.

#### Mandatory Access Control
```
CONFIG_SECURITY=y
CONFIG_SECURITY_APPARMOR=y
CONFIG_SECURITY_APPARMOR_BOOTPARAM_VALUE=1
CONFIG_SECURITY_APPARMOR_HASH=y
```

**Purpose**: Enables AppArmor for mandatory access control.

#### Additional Hardening
```
CONFIG_SECURITY_DMESG_RESTRICT=y       # Restrict kernel log access
CONFIG_PANIC_ON_OOPS=y                  # Panic on kernel oops
CONFIG_BUG=y                            # Enable BUG() assertions
CONFIG_DEBUG_CREDENTIALS=y              # Debug credential usage
CONFIG_STRICT_DEVMEM=y                  # Restrict /dev/mem access
CONFIG_IO_STRICT_DEVMEM=y               # Strict device memory access
```

### Runtime Kernel Parameters

Set in `/etc/sysctl.conf` (to be implemented):

```bash
# Network security
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Address space layout randomization
kernel.randomize_va_space = 2

# Core dumps
kernel.core_uses_pid = 1
fs.suid_dumpable = 0

# Process restrictions
kernel.yama.ptrace_scope = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
```

## Mandatory Access Control (AppArmor)

### AppArmor Profiles

ForgeOS includes AppArmor profiles for all system services in [`security/apparmor/profiles/`](../security/apparmor/profiles/):

#### Dropbear SSH Server
**Profile**: `usr.sbin.dropbear`

**Confinement**:
- Network access: inet/inet6 stream only
- File access: Limited to configuration, host keys, and user directories
- Capabilities: net_bind_service, setuid, setgid, sys_chroot
- Denies: Write access to sensitive system files

**Key Restrictions**:
```
deny /etc/shadow w
deny /etc/passwd w
deny /etc/group w
```

#### Chrony Time Synchronization
**Profile**: `usr.sbin.chronyd`

**Confinement**:
- Network access: inet/inet6 dgram for NTP
- File access: Configuration and drift files only
- Capabilities: sys_time, net_bind_service
- Device access: /dev/ptp*, /dev/rtc*

**Key Restrictions**:
```
deny /etc/shadow rw
deny /home/** rw
deny /root/** rw
```

#### OpenSSH Daemon
**Profile**: `usr.bin.ssh`

**Confinement**:
- Network access: inet/inet6 stream
- File access: SSH configuration, host keys, user .ssh directories
- Capabilities: net_bind_service, setuid, setgid, sys_chroot, audit_write
- Privilege separation: Separate profile for sshd-session

**Key Restrictions**:
```
deny /etc/shadow w
deny /etc/ssh/ssh_host_* w
```

#### Update Agent
**Profile**: `usr.sbin.update-agent`

**Confinement**:
- Network access: inet/inet6 stream for HTTPS
- File access: Update configuration, APK repositories, cache
- Capabilities: Minimal (dac_override, fowner, chown)
- Execution: Can run apk, minisign, cosign

**Key Restrictions**:
```
deny /home/** rw
deny /tmp/** x
deny /var/tmp/** x
```

### Loading AppArmor Profiles

Profiles are loaded at boot via `/etc/init.d/apparmor`:

```bash
# Load all profiles
for profile in /etc/apparmor.d/*; do
    apparmor_parser -r "$profile"
done

# Verify loaded profiles
aa-status
```

## Network Security (nftables)

### Base Firewall Rules

The base firewall ruleset implements a **default-deny** policy in [`security/nftables/base.nft`](../security/nftables/base.nft):

#### Input Chain (Inbound Traffic)
- **Default Policy**: DROP
- **Allowed**:
  - Established/related connections
  - Loopback traffic
  - ICMP (rate limited to 10/second)
  - SSH (rate limited to 5/minute)
- **Blocked**: Everything else (logged)

#### Output Chain (Outbound Traffic)
- **Default Policy**: ACCEPT
- **Allowed**:
  - Established/related connections
  - DNS (port 53 UDP/TCP)
  - NTP/Chrony (ports 123, 323 UDP)
  - HTTPS (port 443)
  - HTTP (port 80, for packages)
- **Logged**: New outbound connections

#### Forward Chain (Routing)
- **Default Policy**: DROP
- Only established/related connections allowed

### DoS Protection

```nft
# SYN flood protection
tcp flags syn tcp flags & (fin|syn|rst|ack) == syn \
    ct state new \
    limit rate over 60/second burst 100 packets \
    drop
```

### Port Scan Detection

```nft
# XMAS scan detection
tcp flags & (fin|syn|rst|psh|ack|urg) == fin|syn|rst|psh|ack|urg \
    log prefix "XMAS-SCAN: " \
    drop

# NULL scan detection
tcp flags & (fin|syn|rst|psh|ack|urg) == 0 \
    log prefix "NULL-SCAN: " \
    drop
```

### Blacklisting

Dynamic blacklist sets for IPv4 and IPv6:

```nft
set blacklist_v4 {
    type ipv4_addr
    flags timeout
}

# Add IPs to blacklist
nft add element inet blacklist blacklist_v4 { 192.0.2.1 timeout 1h }
```

### Loading Firewall Rules

```bash
# Load base rules
nft -f /etc/forgeos/nftables/base.nft

# Verify rules
nft list ruleset

# Show statistics
nft list ruleset -a
```

## Filesystem Security

### Secure Mount Options

All filesystems use security-hardened mount options in [`/etc/fstab`](../userland/overlay-base/etc/fstab):

#### Proc Filesystem
```
proc  /proc  proc  nosuid,nodev,noexec  0 0
```
- `nosuid`: Ignore setuid/setgid bits
- `nodev`: Ignore device nodes
- `noexec`: Prevent execution

#### Sysfs Filesystem
```
sysfs  /sys  sysfs  nosuid,nodev,noexec  0 0
```

#### Temporary Filesystems
```
tmpfs  /tmp  tmpfs  mode=1777,strictatime,noexec,nosuid,nodev,size=512M  0 0
```
- `mode=1777`: Sticky bit set (only owner can delete)
- `strictatime`: Update access times
- `noexec`: No execution from /tmp
- `nosuid`: No setuid binaries
- `nodev`: No device nodes
- `size=512M`: Limit to 512MB

#### Log Filesystem
```
tmpfs  /var/log  tmpfs  mode=0755,nosuid,nodev,noexec,size=128M  0 0
```
- Limited to 128MB to prevent log filling attacks

#### Root Filesystem
```
/dev/vda  /  ext4  defaults,noatime  0 1
```
- `noatime`: Don't update access times (performance + security)
- Optional: Add `ro` for read-only root

### File Permissions

Critical files have restrictive permissions:

```bash
# Sensitive configuration
chmod 600 /etc/shadow
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/passwd
chmod 644 /etc/group

# Service directories
chmod 700 /root
chmod 755 /etc
chmod 755 /var

# Executable permissions
chmod 755 /bin/*
chmod 755 /sbin/*
chmod 4755 /usr/bin/sudo  # or doas
```

## User Separation

### Service Users

All services run as dedicated non-root users defined in [`/etc/passwd`](../userland/overlay-base/etc/passwd):

| User | UID | Purpose | Home Directory | Shell |
|------|-----|---------|----------------|-------|
| sshd | 100 | SSH daemon | /var/empty | /bin/false |
| dropbear | 101 | Dropbear SSH | /var/empty | /bin/false |
| chrony | 102 | Time sync | /var/lib/chrony | /bin/false |
| update | 103 | Update agent | /var/lib/forgeos/updates | /bin/false |
| ntp | 104 | NTP daemon | /var/lib/ntp | /bin/false |
| log | 105 | Log daemon | /var/log | /bin/false |
| systemd-network | 110 | Network management | / | /bin/false |
| systemd-resolve | 111 | DNS resolution | / | /bin/false |
| systemd-timesync | 112 | Time sync | / | /bin/false |

**Key Features**:
- No shell access (`/bin/false`)
- Isolated home directories
- Minimal privileges via AppArmor confinement

### Default User

```
forgeos:x:1000:1000:ForgeOS User:/home/forgeos:/bin/sh
```

- UID 1000 (standard first user)
- Can use `doas` for privilege escalation

### Privilege Escalation Policy

Minimal privilege escalation via `doas` in [`/etc/doas.conf`](../userland/overlay-base/etc/doas.conf):

```
# Allow forgeos user to run commands as root with password
permit persist forgeos as root

# Allow wheel group members
permit persist :wheel

# Deny by default
```

**Security Features**:
- Requires password authentication
- `persist`: Caches auth for short time
- Explicit deny by default

## Package Signing

### Signing Infrastructure

All artifacts are signed with **minisign** (or cosign) in [`scripts/sign_artifacts.sh`](../scripts/sign_artifacts.sh):

#### Key Generation

```bash
# Generate minisign key pair
minisign -G -p security/keys/minisign.pub -s security/keys/minisign.key

# Keys are stored in:
#   Private: security/keys/minisign.key (600 permissions)
#   Public: security/keys/minisign.pub (644 permissions)
```

#### Signing Artifacts

```bash
# Sign all artifacts
./scripts/sign_artifacts.sh artifacts/ minisign

# Creates signatures:
#   artifacts/arch/arm64/boot/Image.minisig
#   artifacts/initramfs.gz.minisig
#   artifacts/root.img.minisig
#   artifacts/SHA256SUMS.minisig
```

#### Verifying Artifacts

```bash
# Verify artifact signature
minisign -V -p security/keys/minisign.pub \
    -m artifacts/arch/arm64/boot/Image \
    -x artifacts/arch/arm64/boot/Image.minisig

# Verify checksums
sha256sum -c artifacts/SHA256SUMS
```

### Package Repository Signing

APK packages and repository indexes are signed:

```bash
# Sign packages
./scripts/sign_packages.sh artifacts/packages/ security/keys/

# Creates:
#   packages/*.apk.sig
#   packages/repo/*/APKINDEX.tar.gz.sig
```

### Public Key Distribution

Public keys are embedded in the OS at `/etc/forgeos/keys/`:

```bash
# Install public keys
install -D -m 644 security/keys/minisign.pub \
    rootfs/etc/forgeos/keys/minisign.pub

# APK public keys
install -D -m 644 security/keys/forgeos-rsa.pub \
    rootfs/etc/apk/keys/forgeos-rsa.pub
```

## Verification

### Kernel Security Verification

```bash
# Check kernel config
zcat /proc/config.gz | grep -E 'RANDOMIZE|STACKPROTECTOR|SECCOMP|APPARMOR'

# Verify KASLR
dmesg | grep KASLR

# Check ASLR
cat /proc/sys/kernel/randomize_va_space  # Should be 2
```

### AppArmor Verification

```bash
# Check AppArmor status
aa-status

# Expected output:
#   apparmor module is loaded.
#   X profiles are loaded.
#   X profiles are in enforce mode.
#   X processes have profiles defined.

# List loaded profiles
cat /sys/kernel/security/apparmor/profiles

# Check specific service
ps aux | grep dropbear
cat /proc/$(pidof dropbear)/attr/current  # Shows AppArmor profile
```

### Firewall Verification

```bash
# List active firewall rules
nft list ruleset

# Check default policies
nft list chain inet filter input   # Should show: policy drop
nft list chain inet filter forward # Should show: policy drop
nft list chain inet filter output  # Should show: policy accept

# View dropped packets (if logged)
dmesg | grep NFT-INPUT-DROP

# Test SSH rate limiting
# Rapid SSH connection attempts should be rate-limited
```

### Mount Options Verification

```bash
# Check mount options
mount | grep -E 'tmp|proc|sys'

# Expected output should show:
#   tmpfs on /tmp type tmpfs (rw,nosuid,nodev,noexec,...)
#   proc on /proc type proc (rw,nosuid,nodev,noexec,...)
#   sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,...)

# Verify /tmp is non-executable
echo '#!/bin/sh\necho test' > /tmp/test.sh
chmod +x /tmp/test.sh
/tmp/test.sh  # Should fail with "Permission denied"
```

### User Verification

```bash
# Check service users exist
getent passwd sshd dropbear chrony update

# Verify no shell access
su - dropbear  # Should fail

# Check user privileges
id dropbear  # Should show only one group

# Verify doas configuration
doas -C /etc/doas.conf
```

### Package Verification

```bash
# Verify artifact signatures
for artifact in artifacts/*.{img,gz}; do
    minisign -V -p security/keys/minisign.pub \
        -m "$artifact" \
        -x "${artifact}.minisig"
done

# Verify checksums
cd artifacts/
sha256sum -c SHA256SUMS

# Check APK signature verification
apk verify forgeos-keys-0.1.0-r0.apk
```

## Security Testing

### Manual Security Tests

```bash
# Test 1: KASLR - Verify randomized addresses
cat /proc/self/maps  # Run multiple times, addresses should change

# Test 2: Stack protection - Try buffer overflow
# (requires test program)

# Test 3: AppArmor - Verify confinement
sudo -u dropbear cat /etc/shadow  # Should be denied

# Test 4: Firewall - Port scan detection
nmap -sS localhost  # Should be logged and blocked

# Test 5: Mount security - Execute from /tmp
echo '#!/bin/sh' > /tmp/test
chmod +x /tmp/test
/tmp/test  # Should fail

# Test 6: File permissions
ls -la /etc/shadow  # Should be 600 or 640

# Test 7: Service user separation
ps aux | grep -E 'sshd|dropbear|chrony'  # Should run as service users

# Test 8: Signature verification
minisign -V -p security/keys/minisign.pub \
    -m artifacts/arch/arm64/boot/Image \
    -x artifacts/arch/arm64/boot/Image.minisig
```

### Automated Security Audit

```bash
# Run security audit script (to be implemented)
./scripts/security_audit.sh

# Expected checks:
#   - Kernel hardening features
#   - AppArmor profile status
#   - Firewall rule verification
#   - Mount option verification
#   - User/permission verification
#   - Package signature verification
```

## Security Maintenance

### Regular Security Tasks

1. **Update Security Keys**
   ```bash
   # Rotate signing keys annually
   ./scripts/rotate_keys.sh
   ```

2. **Review AppArmor Logs**
   ```bash
   # Check for AppArmor denials
   grep DENIED /var/log/audit/audit.log
   aa-logprof  # Tune profiles based on denials
   ```

3. **Monitor Firewall Logs**
   ```bash
   # Review dropped packets
   dmesg | grep NFT-INPUT-DROP
   
   # Check for port scans
   dmesg | grep -E 'XMAS-SCAN|NULL-SCAN|PORT-SCAN'
   ```

4. **Security Updates**
   ```bash
   # Update system packages
   apk update && apk upgrade
   
   # Verify signatures
   apk verify
   ```

5. **Audit User Accounts**
   ```bash
   # List all users
   cat /etc/passwd
   
   # Check for unauthorized accounts
   # Remove or disable unused accounts
   ```

## Security Incidents

### Incident Response Procedure

1. **Detection**: Monitor logs for suspicious activity
2. **Containment**: Isolate affected systems
3. **Investigation**: Analyze logs and forensics
4. **Remediation**: Apply fixes and patches
5. **Recovery**: Restore from verified backups
6. **Lessons Learned**: Update security policies

### Emergency Procedures

```bash
# Block suspicious IP
nft add element inet blacklist blacklist_v4 { <IP> timeout 24h }

# Disable compromised service
rc-service <service> stop
chmod -x /usr/sbin/<service>

# Review running processes
ps auxf
lsof -i  # Check network connections

# Check for rootkits
chkrootkit
rkhunter --check
```

## References

- [ForgeOS Architecture](architecture.md)
- [Kernel Documentation](kernel.md)
- [Security Guidelines](.cursor/rules/security.mdc)
- [AppArmor Documentation](https://gitlab.com/apparmor/apparmor/-/wikis/home)
- [nftables Wiki](https://wiki.nftables.org/)
- [Minisign](https://jedisct1.github.io/minisign/)

## Compliance

ForgeOS security hardening addresses:

- **CIS Benchmarks**: Linux hardening guidelines
- **NIST Cybersecurity Framework**: Core security functions
- **OWASP**: Web application security (where applicable)
- **PCI DSS**: Payment card industry standards (where applicable)
- **HIPAA**: Healthcare data protection (where applicable)

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-03  
**Maintained By**: ForgeOS Security Team

