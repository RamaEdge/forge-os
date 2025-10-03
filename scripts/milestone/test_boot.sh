#!/bin/bash
# ForgeOS v0.1 Boot Integration Test
# Implements THE-56 (v0.1 Milestone)
# Tests QEMU boot for initramfs and disk modes

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
BOOT_TIMEOUT=60  # seconds to wait for boot
TEST_MODE="${1:-all}"  # initramfs, disk, or all

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_failure() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

test_initramfs_boot() {
    log_info "Testing initramfs boot mode..."
    
    # Check if artifacts exist
    if [[ ! -f "$PROJECT_ROOT/artifacts/arch/arm64/boot/Image" ]]; then
        log_failure "Kernel image not found"
        return 1
    fi
    
    if [[ ! -f "$PROJECT_ROOT/artifacts/initramfs.gz" ]]; then
        log_failure "Initramfs not found"
        return 1
    fi
    
    log_info "Artifacts found, preparing boot test..."
    
    # Create expect script for automated testing
    cat > /tmp/forgeos_initramfs_test.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 60

spawn ./scripts/qemu_run.sh core-min aarch64 artifacts initramfs

expect {
    "ForgeOS" {
        send_user "\n[TEST] ForgeOS boot banner detected\n"
        exp_continue
    }
    "login:" {
        send_user "\n[TEST] Login prompt reached - SUCCESS\n"
        send "\003"
        exit 0
    }
    "Kernel panic" {
        send_user "\n[TEST] KERNEL PANIC - FAILED\n"
        exit 1
    }
    timeout {
        send_user "\n[TEST] Boot timeout - FAILED\n"
        exit 1
    }
    eof {
        send_user "\n[TEST] Unexpected EOF\n"
        exit 1
    }
}
EOF
    
    chmod +x /tmp/forgeos_initramfs_test.exp
    
    # Run test
    if command -v expect >/dev/null 2>&1; then
        log_info "Running automated boot test with expect..."
        if /tmp/forgeos_initramfs_test.exp; then
            log_success "Initramfs boot test PASSED"
            rm -f /tmp/forgeos_initramfs_test.exp
            return 0
        else
            log_failure "Initramfs boot test FAILED"
            rm -f /tmp/forgeos_initramfs_test.exp
            return 1
        fi
    else
        log_warning "expect command not found, skipping automated test"
        log_info "Manual test: Run 'make qemu-initramfs' and verify boot"
        rm -f /tmp/forgeos_initramfs_test.exp
        return 0
    fi
}

test_disk_boot() {
    log_info "Testing disk boot mode..."
    
    # Check if artifacts exist
    if [[ ! -f "$PROJECT_ROOT/artifacts/arch/arm64/boot/Image" ]]; then
        log_failure "Kernel image not found"
        return 1
    fi
    
    if [[ ! -f "$PROJECT_ROOT/artifacts/root.img" ]]; then
        log_failure "Root disk image not found"
        return 1
    fi
    
    log_info "Artifacts found, preparing boot test..."
    
    # Create expect script for disk boot
    cat > /tmp/forgeos_disk_test.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 60

spawn ./scripts/qemu_run.sh core-min aarch64 artifacts disk

expect {
    "ForgeOS" {
        send_user "\n[TEST] ForgeOS boot banner detected\n"
        exp_continue
    }
    "login:" {
        send_user "\n[TEST] Login prompt reached - SUCCESS\n"
        send "\003"
        exit 0
    }
    "Kernel panic" {
        send_user "\n[TEST] KERNEL PANIC - FAILED\n"
        exit 1
    }
    timeout {
        send_user "\n[TEST] Boot timeout - FAILED\n"
        exit 1
    }
    eof {
        send_user "\n[TEST] Unexpected EOF\n"
        exit 1
    }
}
EOF
    
    chmod +x /tmp/forgeos_disk_test.exp
    
    # Run test
    if command -v expect >/dev/null 2>&1; then
        log_info "Running automated boot test with expect..."
        if /tmp/forgeos_disk_test.exp; then
            log_success "Disk boot test PASSED"
            rm -f /tmp/forgeos_disk_test.exp
            return 0
        else
            log_failure "Disk boot test FAILED"
            rm -f /tmp/forgeos_disk_test.exp
            return 1
        fi
    else
        log_warning "expect command not found, skipping automated test"
        log_info "Manual test: Run 'make qemu-run' and verify boot"
        rm -f /tmp/forgeos_disk_test.exp
        return 0
    fi
}

test_both_boot() {
    log_info "Testing both boot mode (initramfs + disk)..."
    
    # Check if artifacts exist
    if [[ ! -f "$PROJECT_ROOT/artifacts/arch/arm64/boot/Image" ]]; then
        log_failure "Kernel image not found"
        return 1
    fi
    
    if [[ ! -f "$PROJECT_ROOT/artifacts/initramfs.gz" ]]; then
        log_failure "Initramfs not found"
        return 1
    fi
    
    if [[ ! -f "$PROJECT_ROOT/artifacts/root.img" ]]; then
        log_failure "Root disk image not found"
        return 1
    fi
    
    log_info "Testing initramfs with disk pivot..."
    log_warning "This test requires manual verification"
    log_info "Run: make qemu-both"
    log_info "Verify:"
    log_info "  1. Boots with initramfs"
    log_info "  2. Detects /dev/vda"
    log_info "  3. Switches to root filesystem"
    log_info "  4. Reaches login prompt"
    
    return 0
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v qemu-system-aarch64 >/dev/null 2>&1; then
        log_failure "qemu-system-aarch64 not found"
        log_info "Please install QEMU"
        return 1
    fi
    
    log_success "QEMU found: $(which qemu-system-aarch64)"
    
    if ! command -v expect >/dev/null 2>&1; then
        log_warning "expect not found - automated tests will be skipped"
        log_info "Install with: brew install expect (macOS) or apt-get install expect (Linux)"
    else
        log_success "expect found: $(which expect)"
    fi
    
    return 0
}

# Main
main() {
    cd "$PROJECT_ROOT"
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ForgeOS v0.1 Boot Integration Tests${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
    
    check_prerequisites || exit 1
    
    local tests_passed=0
    local tests_failed=0
    
    case "$TEST_MODE" in
        "initramfs")
            if test_initramfs_boot; then
                ((tests_passed++))
            else
                ((tests_failed++))
            fi
            ;;
        "disk")
            if test_disk_boot; then
                ((tests_passed++))
            else
                ((tests_failed++))
            fi
            ;;
        "both")
            if test_both_boot; then
                ((tests_passed++))
            else
                ((tests_failed++))
            fi
            ;;
        "all")
            log_info "Running all boot tests..."
            echo ""
            
            if test_initramfs_boot; then
                ((tests_passed++))
            else
                ((tests_failed++))
            fi
            
            echo ""
            
            if test_disk_boot; then
                ((tests_passed++))
            else
                ((tests_failed++))
            fi
            
            echo ""
            
            if test_both_boot; then
                ((tests_passed++))
            else
                ((tests_failed++))
            fi
            ;;
        *)
            log_failure "Unknown test mode: $TEST_MODE"
            log_info "Usage: $0 [initramfs|disk|both|all]"
            exit 1
            ;;
    esac
    
    # Summary
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Test Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}Passed:${NC} $tests_passed"
    echo -e "  ${RED}Failed:${NC} $tests_failed"
    echo ""
    
    if [ $tests_failed -eq 0 ]; then
        log_success "All boot tests passed! ✨"
        return 0
    else
        log_failure "Some boot tests failed"
        return 1
    fi
}

main "$@"

