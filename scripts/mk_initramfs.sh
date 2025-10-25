#!/bin/bash
# ForgeOS Initramfs Creation Script
# Implements THE-51 (Root Filesystem & Images)

set -euo pipefail

# Script configuration - Detect project root using git
# This ensures we find the correct root regardless of script location or invocation directory
if ! PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    # Fallback to script-based detection if not in a git repository
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    echo "Warning: Not in a git repository. Using fallback project root detection." >&2
    echo "Project root: $PROJECT_ROOT" >&2
fi

# Parameters
PROFILE="${1:-core-min}"
ARCH="${2:-aarch64}"
BUILD_DIR="${3:-build/initramfs}"
ARTIFACTS_DIR="${4:-artifacts}"

echo "Creating ForgeOS initramfs for profile: $PROFILE on $ARCH"
echo "Build directory: $BUILD_DIR"
echo "Artifacts directory: $ARTIFACTS_DIR"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$ARTIFACTS_DIR"

# Initramfs root directory
INITRAMFS_ROOT="$BUILD_DIR/initramfs"
mkdir -p "$INITRAMFS_ROOT"

# Load toolchain environment
if [[ -f "$PROJECT_ROOT/toolchains/env.musl" ]]; then
    . "$PROJECT_ROOT/toolchains/env.musl"
else
    echo "Error: Toolchain environment not found. Please run 'make toolchain' first."
    exit 1
fi

echo "Cross-compile: $CROSS_COMPILE"

# Create basic directory structure
echo "Creating initramfs directory structure..."
mkdir -p "$INITRAMFS_ROOT"/{bin,sbin,usr/{bin,sbin,lib},etc,var/{log,run,tmp},tmp,proc,sys,dev,run,home,root,mnt,opt}

# Create device nodes
echo "Creating device nodes..."
mkdir -p "$INITRAMFS_ROOT/dev"

# Essential device nodes (will be created by mdev in real system)
mknod "$INITRAMFS_ROOT/dev/console" c 5 1 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$INITRAMFS_ROOT/dev/null" c 1 3 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$INITRAMFS_ROOT/dev/zero" c 1 5 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$INITRAMFS_ROOT/dev/random" c 1 8 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$INITRAMFS_ROOT/dev/urandom" c 1 9 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$INITRAMFS_ROOT/dev/tty" c 5 0 2>/dev/null || echo "Note: mknod requires root privileges"
mknod "$INITRAMFS_ROOT/dev/ttyAMA0" c 204 64 2>/dev/null || echo "Note: mknod requires root privileges"

# Set permissions
echo "Setting permissions..."
chmod 755 "$INITRAMFS_ROOT"
chmod 755 "$INITRAMFS_ROOT"/{bin,sbin,usr,etc,var,tmp,proc,sys,dev,run,home,root,mnt,opt}
chmod 1777 "$INITRAMFS_ROOT/tmp"
chmod 755 "$INITRAMFS_ROOT/var/run"
chmod 755 "$INITRAMFS_ROOT/var/log"

# Copy BusyBox binary
echo "Installing BusyBox..."
if [[ -f "$ARTIFACTS_DIR/busybox/busybox" ]]; then
    cp "$ARTIFACTS_DIR/busybox/busybox" "$INITRAMFS_ROOT/bin/"
    chmod +x "$INITRAMFS_ROOT/bin/busybox"
    
    # Create BusyBox applet symlinks
    echo "Creating BusyBox applet symlinks..."
    cd "$INITRAMFS_ROOT"
    "$INITRAMFS_ROOT/bin/busybox" --install -s .
    cd "$PROJECT_ROOT"
else
    echo "Warning: BusyBox binary not found at $ARTIFACTS_DIR/busybox/busybox"
    echo "Creating placeholder BusyBox..."
    touch "$INITRAMFS_ROOT/bin/busybox"
    chmod +x "$INITRAMFS_ROOT/bin/busybox"
fi

# Copy base overlay
echo "Applying base overlay..."
if [[ -d "$PROJECT_ROOT/userland/overlay-base" ]]; then
    cp -r "$PROJECT_ROOT/userland/overlay-base"/* "$INITRAMFS_ROOT/" 2>/dev/null || true
    echo "Base overlay applied"
else
    echo "Warning: Base overlay not found at $PROJECT_ROOT/userland/overlay-base"
fi

# Apply profile overlay
echo "Applying profile overlay..."
if [[ -d "$PROJECT_ROOT/profiles/$PROFILE/overlay" ]]; then
    cp -r "$PROJECT_ROOT/profiles/$PROFILE/overlay"/* "$INITRAMFS_ROOT/" 2>/dev/null || true
    echo "Profile overlay applied"
else
    echo "Warning: Profile overlay not found at $PROJECT_ROOT/profiles/$PROFILE/overlay"
fi

# Create initramfs init script
echo "Creating initramfs init script..."
cat > "$INITRAMFS_ROOT/init" << 'EOF'
#!/bin/sh
# ForgeOS Initramfs Init Script
# Handles early boot and pivot to root filesystem

set -e

echo "ForgeOS Initramfs Starting..."

# Mount virtual file systems
echo "Mounting virtual file systems..."
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev

# Create device nodes
echo "Creating device nodes..."
mdev -s

# Set up basic networking (if needed)
echo "Setting up loopback..."
ifconfig lo 127.0.0.1 up

# Check for root filesystem
echo "Looking for root filesystem..."
if [ -b /dev/vda ]; then
    echo "Found /dev/vda, attempting to mount as root..."
    
    # Try to mount root filesystem
    if mount -t ext4 /dev/vda /mnt; then
        echo "Root filesystem mounted successfully"
        
        # Switch to root filesystem
        echo "Switching to root filesystem..."
        exec switch_root /mnt /sbin/init
    else
        echo "Failed to mount root filesystem, continuing with initramfs..."
    fi
else
    echo "No root device found, continuing with initramfs..."
fi

# Fallback: continue with initramfs
echo "Continuing with initramfs mode..."
exec /bin/sh
EOF

chmod +x "$INITRAMFS_ROOT/init"

# Create fstab for initramfs
echo "Creating initramfs fstab..."
cat > "$INITRAMFS_ROOT/etc/fstab" << 'EOF'
# ForgeOS Initramfs fstab
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
devtmpfs /dev devtmpfs defaults 0 0
tmpfs /tmp tmpfs defaults 0 0
tmpfs /var/run tmpfs defaults 0 0
EOF

# Create inittab for initramfs
echo "Creating initramfs inittab..."
cat > "$INITRAMFS_ROOT/etc/inittab" << 'EOF'
# ForgeOS Initramfs inittab
::sysinit:/init
ttyAMA0::respawn:/bin/sh
::shutdown:/bin/umount -a -r
EOF

# Set proper permissions on init scripts
if [[ -f "$INITRAMFS_ROOT/etc/init.d/rcS" ]]; then
    chmod +x "$INITRAMFS_ROOT/etc/init.d/rcS"
fi
if [[ -f "$INITRAMFS_ROOT/etc/init.d/rcK" ]]; then
    chmod +x "$INITRAMFS_ROOT/etc/init.d/rcK"
fi

# Create initramfs archive
echo "Creating initramfs archive..."
INITRAMFS_FILE="$ARTIFACTS_DIR/initramfs.gz"
cd "$INITRAMFS_ROOT"
find . | cpio -o -H newc | gzip > "$INITRAMFS_FILE"
cd "$PROJECT_ROOT"

echo "Initramfs created successfully: $INITRAMFS_FILE"
echo "Size: $(du -h "$INITRAMFS_FILE" | cut -f1)"

# Show initramfs contents
echo "Initramfs contents:"
echo "  Binary: $INITRAMFS_ROOT/bin/busybox"
echo "  Init script: $INITRAMFS_ROOT/init"
echo "  Config: $INITRAMFS_ROOT/etc/inittab"
echo "  Fstab: $INITRAMFS_ROOT/etc/fstab"

# Verify initramfs
echo "Verifying initramfs..."
if [[ -f "$INITRAMFS_FILE" ]]; then
    echo "✓ Initramfs archive created: $INITRAMFS_FILE"
    file "$INITRAMFS_FILE"
else
    echo "✗ Error: Initramfs archive not created"
    exit 1
fi

echo "ForgeOS initramfs creation completed successfully"
echo "Initramfs file: $INITRAMFS_FILE"
echo "Ready for QEMU testing with: -initrd $INITRAMFS_FILE"

exit 0