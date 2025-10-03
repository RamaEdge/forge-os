#!/bin/bash
# ForgeOS v0.1 Milestone Verification Script
# Implements THE-56 (v0.1 Milestone)
# Verifies all components for the v0.1 release

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0
CHECKS_TOTAL=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((CHECKS_PASSED++))
    ((CHECKS_TOTAL++))
}

log_failure() {
    echo -e "${RED}[✗]${NC} $1"
    ((CHECKS_FAILED++))
    ((CHECKS_TOTAL++))
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    ((CHECKS_WARNING++))
    ((CHECKS_TOTAL++))
}

log_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
}

# Verification functions
verify_project_structure() {
    log_section "Project Structure"
    
    local required_dirs=(
        "toolchains"
        "kernel"
        "userland"
        "packages"
        "profiles"
        "security"
        "scripts"
        "docs"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            log_success "Directory exists: $dir"
        else
            log_failure "Missing directory: $dir"
        fi
    done
}

verify_toolchain() {
    log_section "Toolchain (THE-46)"
    
    # Check toolchain files
    if [[ -f "$PROJECT_ROOT/toolchains/versions.mk" ]]; then
        log_success "Toolchain versions.mk exists"
    else
        log_failure "Missing toolchains/versions.mk"
    fi
    
    if [[ -f "$PROJECT_ROOT/toolchains/env.musl" ]]; then
        log_success "Musl environment helper exists"
    else
        log_failure "Missing toolchains/env.musl"
    fi
    
    # Check if toolchain artifacts exist
    if [[ -d "$PROJECT_ROOT/build/toolchain" ]]; then
        log_success "Toolchain build directory exists"
    else
        log_warning "Toolchain not built yet (build/toolchain missing)"
    fi
}

verify_kernel() {
    log_section "Linux Kernel (THE-47)"
    
    # Check kernel configuration
    if [[ -f "$PROJECT_ROOT/kernel/configs/aarch64_defconfig" ]]; then
        log_success "Kernel config exists"
        
        # Check for security features
        if grep -q "CONFIG_RANDOMIZE_BASE=y" "$PROJECT_ROOT/kernel/configs/aarch64_defconfig"; then
            log_success "KASLR enabled in kernel config"
        else
            log_failure "KASLR not enabled"
        fi
        
        if grep -q "CONFIG_STACKPROTECTOR_STRONG=y" "$PROJECT_ROOT/kernel/configs/aarch64_defconfig"; then
            log_success "Stack protection enabled"
        else
            log_failure "Stack protection not enabled"
        fi
        
        if grep -q "CONFIG_SECCOMP=y" "$PROJECT_ROOT/kernel/configs/aarch64_defconfig"; then
            log_success "SECCOMP enabled"
        else
            log_failure "SECCOMP not enabled"
        fi
        
        if grep -q "CONFIG_SECURITY_APPARMOR=y" "$PROJECT_ROOT/kernel/configs/aarch64_defconfig"; then
            log_success "AppArmor enabled"
        else
            log_failure "AppArmor not enabled"
        fi
    else
        log_failure "Missing kernel config"
    fi
    
    # Check kernel artifacts
    if [[ -f "$PROJECT_ROOT/artifacts/arch/arm64/boot/Image" ]]; then
        log_success "Kernel image built"
    else
        log_warning "Kernel not built yet"
    fi
}

verify_userland() {
    log_section "Userland Base (THE-48)"
    
    # Check BusyBox
    if [[ -f "$PROJECT_ROOT/userland/busybox/configs/busybox_defconfig" ]]; then
        log_success "BusyBox config exists"
    else
        log_failure "Missing BusyBox config"
    fi
    
    # Check overlay
    if [[ -d "$PROJECT_ROOT/userland/overlay-base" ]]; then
        log_success "Base overlay exists"
        
        # Check critical overlay files
        local overlay_files=(
            "etc/passwd"
            "etc/group"
            "etc/fstab"
            "etc/inittab"
            "etc/motd"
        )
        
        for file in "${overlay_files[@]}"; do
            if [[ -f "$PROJECT_ROOT/userland/overlay-base/$file" ]]; then
                log_success "Overlay file: $file"
            else
                log_failure "Missing overlay file: $file"
            fi
        done
    else
        log_failure "Missing base overlay directory"
    fi
    
    # Check BusyBox artifacts
    if [[ -f "$PROJECT_ROOT/artifacts/busybox/busybox" ]]; then
        log_success "BusyBox binary built"
    else
        log_warning "BusyBox not built yet"
    fi
}

verify_profiles() {
    log_section "Profiles (THE-49)"
    
    local profiles=("core-min" "core-net")
    
    for profile in "${profiles[@]}"; do
        if [[ -d "$PROJECT_ROOT/profiles/$profile" ]]; then
            log_success "Profile exists: $profile"
            
            # Check profile components
            if [[ -f "$PROJECT_ROOT/profiles/$profile/packages.txt" ]]; then
                log_success "  packages.txt for $profile"
            else
                log_warning "  Missing packages.txt for $profile"
            fi
            
            if [[ -d "$PROJECT_ROOT/profiles/$profile/overlay" ]]; then
                log_success "  overlay directory for $profile"
            else
                log_warning "  Missing overlay for $profile"
            fi
        else
            log_failure "Missing profile: $profile"
        fi
    done
}

verify_security() {
    log_section "Security Baseline (THE-52)"
    
    # Check AppArmor profiles
    if [[ -d "$PROJECT_ROOT/security/apparmor/profiles" ]]; then
        log_success "AppArmor profiles directory exists"
        
        local profiles=(
            "usr.sbin.dropbear"
            "usr.sbin.chronyd"
            "usr.bin.ssh"
            "usr.sbin.update-agent"
        )
        
        for profile in "${profiles[@]}"; do
            if [[ -f "$PROJECT_ROOT/security/apparmor/profiles/$profile" ]]; then
                log_success "  AppArmor profile: $profile"
            else
                log_failure "  Missing AppArmor profile: $profile"
            fi
        done
    else
        log_failure "Missing AppArmor profiles directory"
    fi
    
    # Check nftables rules
    if [[ -f "$PROJECT_ROOT/security/nftables/base.nft" ]]; then
        log_success "nftables base rules exist"
        
        # Check for default-deny policy
        if grep -q "policy drop" "$PROJECT_ROOT/security/nftables/base.nft"; then
            log_success "  nftables default-deny policy configured"
        else
            log_failure "  Missing default-deny policy"
        fi
    else
        log_failure "Missing nftables rules"
    fi
    
    # Check signing infrastructure
    if [[ -f "$PROJECT_ROOT/scripts/sign_artifacts.sh" ]]; then
        log_success "Artifact signing script exists"
    else
        log_failure "Missing artifact signing script"
    fi
    
    if [[ -f "$PROJECT_ROOT/scripts/sign_packages.sh" ]]; then
        log_success "Package signing script exists"
    else
        log_failure "Missing package signing script"
    fi
}

verify_networking() {
    log_section "Networking (THE-53)"
    
    # Check DHCP client script
    if [[ -f "$PROJECT_ROOT/userland/overlay-base/usr/share/udhcpc/default.script" ]]; then
        log_success "udhcpc DHCP script exists"
    else
        log_failure "Missing udhcpc script"
    fi
    
    # Check chrony configuration
    if [[ -f "$PROJECT_ROOT/userland/overlay-base/etc/chrony/chrony.conf" ]]; then
        log_success "Chrony configuration exists"
    else
        log_failure "Missing chrony configuration"
    fi
    
    # Check network init scripts
    if [[ -f "$PROJECT_ROOT/userland/overlay-base/etc/init.d/networking" ]]; then
        log_success "Networking init script exists"
    else
        log_failure "Missing networking init script"
    fi
    
    if [[ -f "$PROJECT_ROOT/userland/overlay-base/etc/init.d/nftables" ]]; then
        log_success "nftables init script exists"
    else
        log_failure "Missing nftables init script"
    fi
    
    if [[ -f "$PROJECT_ROOT/userland/overlay-base/etc/init.d/chronyd" ]]; then
        log_success "chronyd init script exists"
    else
        log_failure "Missing chronyd init script"
    fi
}

verify_packages() {
    log_section "Package System (THE-50)"
    
    # Check package system
    if [[ -f "$PROJECT_ROOT/packages/versions.mk" ]]; then
        log_success "Package versions file exists"
    else
        log_failure "Missing packages/versions.mk"
    fi
    
    # Check package sources
    if [[ -d "$PROJECT_ROOT/packages/sources" ]]; then
        log_success "Package sources directory exists"
        
        local packages=("iproute2" "chrony" "dropbear" "nftables" "ca-certificates")
        for pkg in "${packages[@]}"; do
            if [[ -d "$PROJECT_ROOT/packages/sources/$pkg" ]]; then
                log_success "  Package source: $pkg"
            else
                log_warning "  Missing package source: $pkg"
            fi
        done
    else
        log_failure "Missing package sources directory"
    fi
    
    # Check repository
    if [[ -d "$PROJECT_ROOT/packages/repo" ]]; then
        log_success "Package repository directory exists"
    else
        log_warning "Package repository not initialized"
    fi
}

verify_images() {
    log_section "Root Filesystem & Images (THE-51)"
    
    # Check scripts
    if [[ -f "$PROJECT_ROOT/scripts/mk_rootfs.sh" ]]; then
        log_success "Root filesystem creation script exists"
    else
        log_failure "Missing mk_rootfs.sh"
    fi
    
    if [[ -f "$PROJECT_ROOT/scripts/mk_initramfs.sh" ]]; then
        log_success "Initramfs creation script exists"
    else
        log_failure "Missing mk_initramfs.sh"
    fi
    
    if [[ -f "$PROJECT_ROOT/scripts/mk_disk.sh" ]]; then
        log_success "Disk image creation script exists"
    else
        log_failure "Missing mk_disk.sh"
    fi
    
    # Check QEMU runner
    if [[ -f "$PROJECT_ROOT/scripts/qemu_run.sh" ]]; then
        log_success "QEMU runner script exists"
    else
        log_failure "Missing qemu_run.sh"
    fi
    
    # Check artifacts
    if [[ -f "$PROJECT_ROOT/artifacts/initramfs.gz" ]]; then
        log_success "Initramfs artifact exists"
    else
        log_warning "Initramfs not built yet"
    fi
    
    if [[ -f "$PROJECT_ROOT/artifacts/root.img" ]]; then
        log_success "Root disk image exists"
    else
        log_warning "Root disk image not built yet"
    fi
}

verify_documentation() {
    log_section "Documentation"
    
    local docs=(
        "README.md"
        "docs/architecture.md"
        "docs/implementation_plan.md"
        "docs/hardening.md"
        "docs/toolchains.md"
        "docs/kernel.md"
        "docs/profiles.md"
    )
    
    for doc in "${docs[@]}"; do
        if [[ -f "$PROJECT_ROOT/$doc" ]]; then
            log_success "Documentation: $doc"
        else
            log_warning "Missing documentation: $doc"
        fi
    done
}

verify_makefile() {
    log_section "Build System"
    
    if [[ -f "$PROJECT_ROOT/Makefile" ]]; then
        log_success "Main Makefile exists"
        
        # Check for important targets
        local targets=(
            "toolchain"
            "kernel"
            "busybox"
            "packages"
            "rootfs"
            "initramfs"
            "image"
            "qemu-run"
            "sign"
            "release"
        )
        
        for target in "${targets[@]}"; do
            if grep -q "^$target:" "$PROJECT_ROOT/Makefile"; then
                log_success "  Makefile target: $target"
            else
                log_failure "  Missing Makefile target: $target"
            fi
        done
    else
        log_failure "Missing main Makefile"
    fi
}

# Main verification
main() {
    log_info "ForgeOS v0.1 Milestone Verification"
    log_info "Starting comprehensive system check..."
    echo ""
    
    cd "$PROJECT_ROOT"
    
    # Run all verifications
    verify_project_structure
    verify_toolchain
    verify_kernel
    verify_userland
    verify_profiles
    verify_security
    verify_networking
    verify_packages
    verify_images
    verify_documentation
    verify_makefile
    
    # Summary
    log_section "Verification Summary"
    echo ""
    echo -e "  ${GREEN}Passed:${NC}   $CHECKS_PASSED"
    echo -e "  ${RED}Failed:${NC}   $CHECKS_FAILED"
    echo -e "  ${YELLOW}Warnings:${NC} $CHECKS_WARNING"
    echo -e "  ──────────────"
    echo -e "  Total:    $CHECKS_TOTAL"
    echo ""
    
    # Calculate percentage
    if [ $CHECKS_TOTAL -gt 0 ]; then
        PASS_PERCENTAGE=$((CHECKS_PASSED * 100 / CHECKS_TOTAL))
        echo -e "  Success rate: ${GREEN}${PASS_PERCENTAGE}%${NC}"
    fi
    
    echo ""
    
    # Exit status
    if [ $CHECKS_FAILED -eq 0 ]; then
        log_success "All critical checks passed! ✨"
        if [ $CHECKS_WARNING -gt 0 ]; then
            log_warning "Some components not yet built (run 'make all')"
        fi
        return 0
    else
        log_failure "Some critical checks failed"
        log_info "Please address the failures before release"
        return 1
    fi
}

main "$@"

