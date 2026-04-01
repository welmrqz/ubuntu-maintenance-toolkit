#!/bin/bash

# System Update Script for Ubuntu 24.04+
# Usage: ./update.sh [--check] [--no-log]

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Configuration
CHECK_ONLY=false
ENABLE_LOGGING=true
LOG_DIR="$HOME/.local/share/system-update-logs"
LOG_FILE=""
ERRORS_OCCURRED=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --check)
            CHECK_ONLY=true
            shift
            ;;
        --no-log)
            ENABLE_LOGGING=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --check     Preview updates without applying them"
            echo "  --no-log    Disable logging to file"
            echo "  --help      Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Setup logging
if [ "$ENABLE_LOGGING" = true ]; then
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/update-$(date +%Y%m%d-%H%M%S).log"
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

# Helper functions
print_header() {
    echo -e "\n${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}$1${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "${BOLD}${BLUE}▶${NC} ${BOLD}[$1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ERRORS_OCCURRED=true
}

print_info() {
    echo -e "${DIM}  ℹ $1${NC}"
}

print_skip() {
    echo -e "${DIM}⊘ $1${NC}"
}

# Check for required privileges
check_privileges() {
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        print_warning "This script requires sudo privileges"
        echo ""
    fi
}

# Check if another package manager is running
check_locks() {
    if sudo lsof /var/lib/dpkg/lock-frontend &>/dev/null || \
       sudo lsof /var/lib/apt/lists/lock &>/dev/null || \
       sudo lsof /var/cache/apt/archives/lock &>/dev/null; then
        print_error "Another package manager is running. Please wait for it to finish."
        exit 1
    fi
}

# Main script
print_header "System Update Script for Ubuntu"

if [ "$CHECK_ONLY" = true ]; then
    print_info "Running in CHECK mode - no changes will be made"
    echo ""
fi

if [ "$ENABLE_LOGGING" = true ]; then
    print_info "Logging to: ${LOG_FILE}"
    echo ""
fi

check_privileges
check_locks

# Step 1: Update APT package lists
print_step "1/9" "Updating APT package lists"
if sudo apt update; then
    print_success "Package lists updated"
else
    print_error "Failed to update package lists"
    exit 1
fi

# Step 2: Check for upgrades
echo ""
print_step "2/9" "Checking for package upgrades"
UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || true)
if [ "$UPGRADABLE" -gt 0 ]; then
    print_success "$UPGRADABLE packages can be upgraded"
    echo ""
    print_info "Available upgrades:"
    apt list --upgradable 2>/dev/null | tail -n +2 | head -20
    if [ "$UPGRADABLE" -gt 20 ]; then
        print_info "... and $(($UPGRADABLE - 20)) more"
    fi
else
    print_success "All packages are up to date"
fi

if [ "$CHECK_ONLY" = true ]; then
    echo ""
    print_step "3/9" "Checking dist-upgrade changes"
    sudo apt dist-upgrade -s | grep -E "^(Inst|Remv|Conf)" || print_info "No dist-upgrade changes needed"

    echo ""
    print_header "Check Complete - Exiting (use without --check to apply updates)"
    exit 0
fi

# Step 3: Upgrade packages
echo ""
print_step "3/9" "Upgrading APT packages"
if sudo apt upgrade -y; then
    print_success "Packages upgraded successfully"
else
    print_error "Package upgrade encountered errors"
fi

# Step 4: Dist-upgrade
echo ""
print_step "4/9" "Running distribution upgrade"
print_warning "This may install/remove packages for system upgrades"
if sudo apt dist-upgrade -y; then
    print_success "Distribution upgrade completed"
else
    print_error "Distribution upgrade encountered errors"
fi

# Step 5: Remove unused packages and old kernels
echo ""
print_step "5/9" "Removing unused packages and old kernels"
if sudo apt autoremove --purge -y; then
    print_success "Unused packages removed"
else
    print_warning "Autoremove encountered issues"
fi

if sudo apt autoclean; then
    print_success "Package cache cleaned"
fi

# Step 6: Update Snap packages
echo ""
print_step "6/9" "Updating Snap packages"
if command -v snap &> /dev/null; then
    if sudo snap refresh 2>&1; then
        print_success "Snap packages updated"
    else
        print_warning "Some snap updates may have failed"
    fi
else
    print_skip "Snap not installed, skipping"
fi

# Step 7: Update Flatpak packages
echo ""
print_step "7/9" "Updating Flatpak packages"
if command -v flatpak &> /dev/null; then
    if flatpak update -y; then
        print_success "Flatpak packages updated"
    else
        print_warning "Flatpak update encountered issues"
    fi
else
    print_skip "Flatpak not installed, skipping"
fi

# Step 8: Update firmware
echo ""
print_step "8/9" "Checking for firmware updates"
if command -v fwupdmgr &> /dev/null; then
    print_info "Refreshing firmware metadata..."
    if sudo fwupdmgr refresh --force &>/dev/null || true; then
        FIRMWARE_UPDATES=$(fwupdmgr get-updates 2>/dev/null | grep -c "Update Version" || true)
        if [ "$FIRMWARE_UPDATES" -gt 0 ]; then
            print_warning "Found $FIRMWARE_UPDATES firmware update(s) available"
            print_info "Run 'fwupdmgr update' to install firmware updates"
        else
            print_success "Firmware is up to date"
        fi
    fi
else
    print_skip "fwupd not installed, skipping firmware check"
    print_info "Install with: sudo apt install fwupd"
fi

# Step 9: Update development tools
echo ""
print_step "9/9" "Updating development tools"

# Deno
if command -v deno &> /dev/null; then
    print_info "Updating Deno..."
    if deno upgrade 2>&1 | grep -q "upgraded successfully\|already"; then
        print_success "Deno updated"
    fi
else
    print_skip "Deno not installed"
fi

# Rust/Cargo
if command -v rustup &> /dev/null; then
    print_info "Updating Rust..."
    if rustup update &>/dev/null; then
        print_success "Rust updated"
    fi
else
    print_skip "Rust not installed"
fi

# Node Version Manager
if [ -d "$HOME/.nvm" ]; then
    print_info "NVM detected (manual update recommended)"
    print_info "Run: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash"
else
    print_skip "NVM not installed"
fi

# Final cleanup
echo ""
print_header "Cleanup and Summary"
print_info "Performing final cleanup..."
sudo apt clean
sudo journalctl --vacuum-time=3d &>/dev/null && print_success "Journal logs cleaned (kept 3 days)" || true

# System information
echo ""
print_info "System Information:"
echo -e "${DIM}  ├─ Distribution: $(lsb_release -ds)${NC}"
echo -e "${DIM}  ├─ Kernel: $(uname -r)${NC}"
echo -e "${DIM}  └─ Updated: $(date)${NC}"

# Check for reboot requirement
echo ""
if [ -f /var/run/reboot-required ]; then
    print_warning "A system reboot is required!"
    if [ -f /var/run/reboot-required.pkgs ]; then
        print_info "Packages requiring reboot:"
        while read -r pkg; do
            echo -e "${DIM}    • $pkg${NC}"
        done < /var/run/reboot-required.pkgs
    fi
    echo ""
    echo -e "${YELLOW}${BOLD}  Reboot recommended: sudo reboot${NC}"
else
    print_success "No reboot required"
fi

# Summary
echo ""
print_header "Update Complete!"

if [ "$ERRORS_OCCURRED" = true ]; then
    print_warning "Some operations encountered errors (see above)"
    exit 1
else
    print_success "All updates completed successfully"
fi

if [ "$ENABLE_LOGGING" = true ]; then
    echo ""
    print_info "Full log saved to: ${LOG_FILE}"
fi

echo ""
