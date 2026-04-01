#!/bin/bash

# Ubuntu First-Time Initialization Script for Ubuntu 24.04+
# Usage: ./initialize.sh [--minimal|--standard|--full] [--non-interactive] [--dry-run]

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
PRESET_MODE="interactive"  # interactive, minimal, standard, full
DRY_RUN=false
INTERACTIVE=true
ENABLE_LOGGING=true
LOG_DIR="$HOME/.local/share/system-init-logs"
LOG_FILE=""
BACKUP_DIR="$HOME/.config-backups-$(date +%Y%m%d-%H%M%S)"
ERRORS_OCCURRED=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --minimal)
            PRESET_MODE="minimal"
            INTERACTIVE=false
            shift
            ;;
        --standard)
            PRESET_MODE="standard"
            INTERACTIVE=false
            shift
            ;;
        --full)
            PRESET_MODE="full"
            INTERACTIVE=false
            shift
            ;;
        --non-interactive)
            INTERACTIVE=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-log)
            ENABLE_LOGGING=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Preset Modes:"
            echo "  --minimal         Critical security only (UFW, unattended-upgrades, fail2ban)"
            echo "  --standard        Minimal + common tools + basic config (recommended)"
            echo "  --full            Everything including dev tools and optimizations"
            echo ""
            echo "Options:"
            echo "  --non-interactive Run without prompts (uses defaults)"
            echo "  --dry-run         Show what would be done without doing it"
            echo "  --no-log          Disable logging to file"
            echo "  --help            Show this help message"
            echo ""
            echo "Default: Interactive mode (asks before each section)"
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
    LOG_FILE="$LOG_DIR/initialize-$(date +%Y%m%d-%H%M%S).log"
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

# Helper functions
print_header() {
    echo -e "\n${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}$1${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "${BOLD}${BLUE}▶${NC} ${BOLD}$1${NC}"
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

# Execute or simulate command
execute_or_simulate() {
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would execute: $*"
        return 0
    else
        "$@"
    fi
}

# Ask yes/no question (returns 0 for yes, 1 for no)
ask_yes_no() {
    local question="$1"
    local default="${2:-y}"  # default is 'y' if not specified

    if [ "$INTERACTIVE" = false ]; then
        [[ "$default" == "y" ]] && return 0 || return 1
    fi

    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    while true; do
        read -rp "$(echo -e "${YELLOW}?${NC} $question $prompt: ")" response
        response=${response:-$default}
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Backup a file before modifying
backup_file() {
    local file="$1"
    if [ -f "$file" ] && [ "$DRY_RUN" = false ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/$(basename "$file").backup"
        print_info "Backed up to: $BACKUP_DIR/$(basename "$file").backup"
    fi
}

# Check if running on Ubuntu
check_ubuntu() {
    if [ ! -f /etc/lsb-release ]; then
        print_error "This script is designed for Ubuntu systems"
        exit 1
    fi

    source /etc/lsb-release
    if [[ ! "$DISTRIB_ID" == "Ubuntu" ]]; then
        print_error "This script is designed for Ubuntu systems"
        exit 1
    fi

    # Check version
    VERSION_NUM=$(echo "$DISTRIB_RELEASE" | cut -d. -f1)
    if [ "$VERSION_NUM" -lt 24 ]; then
        print_warning "This script is optimized for Ubuntu 24.04+. You have $DISTRIB_RELEASE"
        if ! ask_yes_no "Continue anyway?" "n"; then
            exit 0
        fi
    fi
}

# Main script
print_header "Ubuntu First-Time Initialization Script"

check_ubuntu

if [ "$DRY_RUN" = true ]; then
    print_warning "Running in DRY-RUN mode - no changes will be made"
    echo ""
fi

if [ "$PRESET_MODE" != "interactive" ]; then
    print_info "Running in $PRESET_MODE mode"
    echo ""
fi

# Show what will be done
echo -e "${BOLD}This script will configure:${NC}"
case "$PRESET_MODE" in
    minimal)
        echo -e "${DIM}  • UFW Firewall${NC}"
        echo -e "${DIM}  • Automatic security updates${NC}"
        echo -e "${DIM}  • fail2ban for SSH protection${NC}"
        ;;
    standard)
        echo -e "${DIM}  • UFW Firewall${NC}"
        echo -e "${DIM}  • Automatic security updates${NC}"
        echo -e "${DIM}  • fail2ban for SSH protection${NC}"
        echo -e "${DIM}  • Essential system utilities${NC}"
        echo -e "${DIM}  • Basic system configuration${NC}"
        echo -e "${DIM}  • User experience improvements${NC}"
        ;;
    full)
        echo -e "${DIM}  • UFW Firewall${NC}"
        echo -e "${DIM}  • Automatic security updates${NC}"
        echo -e "${DIM}  • fail2ban for SSH protection${NC}"
        echo -e "${DIM}  • SSH hardening${NC}"
        echo -e "${DIM}  • Essential system utilities${NC}"
        echo -e "${DIM}  • Development tools${NC}"
        echo -e "${DIM}  • System optimizations${NC}"
        echo -e "${DIM}  • User experience improvements${NC}"
        ;;
    interactive)
        echo -e "${DIM}  • You will be asked for each section${NC}"
        ;;
esac
echo ""

if [ "$INTERACTIVE" = true ] && [ "$PRESET_MODE" = "interactive" ]; then
    if ! ask_yes_no "Continue with initialization?" "y"; then
        echo "Installation cancelled."
        exit 0
    fi
    echo ""
fi

# Update package lists first
print_step "Updating package lists"
if execute_or_simulate sudo apt update; then
    print_success "Package lists updated"
else
    print_error "Failed to update package lists"
    exit 1
fi

# ============================================================================
# SECTION 1: UFW Firewall
# ============================================================================
DO_UFW=false
case "$PRESET_MODE" in
    minimal|standard|full) DO_UFW=true ;;
    interactive) ask_yes_no "Configure UFW firewall?" "y" && DO_UFW=true ;;
esac

if [ "$DO_UFW" = true ]; then
    echo ""
    print_header "Configuring UFW Firewall"

    if ! command -v ufw &> /dev/null; then
        print_info "Installing UFW..."
        execute_or_simulate sudo apt install -y ufw
    fi

    if [ "$DRY_RUN" = false ]; then
        UFW_STATUS=$(sudo ufw status | head -1 | awk '{print $2}')
        print_info "Current UFW status: $UFW_STATUS"
    fi

    # Check if SSH is running
    SSH_RUNNING=false
    if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
        SSH_RUNNING=true
    fi

    if [ "$SSH_RUNNING" = true ]; then
        print_warning "SSH is running - will allow SSH before enabling firewall"
        ALLOW_SSH=true
    else
        ALLOW_SSH=false
        if [ "$INTERACTIVE" = true ]; then
            ask_yes_no "Allow SSH (port 22)?" "n" && ALLOW_SSH=true
        fi
    fi

    print_info "Configuring UFW rules..."
    execute_or_simulate sudo ufw --force reset
    execute_or_simulate sudo ufw default deny incoming
    execute_or_simulate sudo ufw default allow outgoing

    if [ "$ALLOW_SSH" = true ]; then
        execute_or_simulate sudo ufw allow ssh
        print_success "SSH access allowed (port 22)"
    fi

    # Ask for additional ports
    if [ "$INTERACTIVE" = true ]; then
        if ask_yes_no "Allow HTTP (port 80)?" "n"; then
            execute_or_simulate sudo ufw allow 80/tcp
        fi
        if ask_yes_no "Allow HTTPS (port 443)?" "n"; then
            execute_or_simulate sudo ufw allow 443/tcp
        fi
    fi

    execute_or_simulate sudo ufw --force enable
    print_success "UFW firewall configured and enabled"

    if [ "$DRY_RUN" = false ]; then
        print_info "Firewall status:"
        sudo ufw status verbose | head -10
    fi
fi

# ============================================================================
# SECTION 2: Automatic Security Updates
# ============================================================================
DO_AUTOUPDATE=false
case "$PRESET_MODE" in
    minimal|standard|full) DO_AUTOUPDATE=true ;;
    interactive) ask_yes_no "Enable automatic security updates?" "y" && DO_AUTOUPDATE=true ;;
esac

if [ "$DO_AUTOUPDATE" = true ]; then
    echo ""
    print_header "Configuring Automatic Security Updates"

    print_info "Installing unattended-upgrades..."
    execute_or_simulate sudo apt install -y unattended-upgrades update-notifier-common

    if [ "$DRY_RUN" = false ]; then
        backup_file "/etc/apt/apt.conf.d/50unattended-upgrades"

        # Configure unattended-upgrades
        sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

        # Enable automatic updates
        sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
    fi

    print_success "Automatic security updates enabled"
    print_info "Security updates will be installed automatically"
    print_info "System will NOT automatically reboot (configure if needed)"
fi

# ============================================================================
# SECTION 3: fail2ban
# ============================================================================
DO_FAIL2BAN=false
case "$PRESET_MODE" in
    minimal|standard|full) DO_FAIL2BAN=true ;;
    interactive) ask_yes_no "Install and configure fail2ban (SSH protection)?" "y" && DO_FAIL2BAN=true ;;
esac

if [ "$DO_FAIL2BAN" = true ]; then
    echo ""
    print_header "Installing fail2ban"

    print_info "Installing fail2ban..."
    execute_or_simulate sudo apt install -y fail2ban

    if [ "$DRY_RUN" = false ]; then
        # Create local configuration
        sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

        execute_or_simulate sudo systemctl enable fail2ban
        execute_or_simulate sudo systemctl restart fail2ban
    fi

    print_success "fail2ban installed and configured"
    print_info "SSH will be protected from brute force attacks"
fi

# ============================================================================
# SECTION 4: Essential System Utilities
# ============================================================================
DO_UTILITIES=false
case "$PRESET_MODE" in
    standard|full) DO_UTILITIES=true ;;
    interactive) ask_yes_no "Install essential system utilities?" "y" && DO_UTILITIES=true ;;
esac

if [ "$DO_UTILITIES" = true ]; then
    echo ""
    print_header "Installing Essential Utilities"

    UTILITIES=(
        "curl"
        "wget"
        "git"
        "vim"
        "htop"
        "ncdu"
        "tree"
        "net-tools"
        "dnsutils"
        "zip"
        "unzip"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
    )

    print_info "Installing: ${UTILITIES[*]}"
    execute_or_simulate sudo apt install -y "${UTILITIES[@]}"
    print_success "Essential utilities installed"
fi

# ============================================================================
# SECTION 5: Development Tools
# ============================================================================
DO_DEVTOOLS=false
case "$PRESET_MODE" in
    full) DO_DEVTOOLS=true ;;
    interactive) ask_yes_no "Install development tools (build-essential, etc.)?" "n" && DO_DEVTOOLS=true ;;
esac

if [ "$DO_DEVTOOLS" = true ]; then
    echo ""
    print_header "Installing Development Tools"

    DEVTOOLS=(
        "build-essential"
        "make"
        "cmake"
        "pkg-config"
        "libssl-dev"
        "python3-pip"
        "python3-venv"
    )

    print_info "Installing: ${DEVTOOLS[*]}"
    execute_or_simulate sudo apt install -y "${DEVTOOLS[@]}"
    print_success "Development tools installed"
fi

# ============================================================================
# SECTION 6: SSH Hardening
# ============================================================================
DO_SSH_HARDENING=false
case "$PRESET_MODE" in
    full) DO_SSH_HARDENING=true ;;
    interactive)
        if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
            ask_yes_no "Harden SSH configuration?" "y" && DO_SSH_HARDENING=true
        fi
        ;;
esac

if [ "$DO_SSH_HARDENING" = true ]; then
    echo ""
    print_header "SSH Hardening"

    if [ -f /etc/ssh/sshd_config ]; then
        backup_file "/etc/ssh/sshd_config"

        print_warning "This will modify SSH configuration"
        print_info "Changes: Disable root login, disable password auth (key-only)"

        if [ "$INTERACTIVE" = true ]; then
            if ! ask_yes_no "Continue with SSH hardening?" "y"; then
                print_skip "SSH hardening skipped"
                DO_SSH_HARDENING=false
            fi
        fi

        if [ "$DO_SSH_HARDENING" = true ] && [ "$DRY_RUN" = false ]; then
            # Apply hardening settings
            sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
            sudo sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
            sudo sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config

            # Test configuration
            if sudo sshd -t; then
                execute_or_simulate sudo systemctl reload sshd || sudo systemctl reload ssh
                print_success "SSH hardening applied"
                print_warning "Ensure you have SSH keys set up before logging out!"
            else
                print_error "SSH configuration test failed - reverting"
                sudo cp "$BACKUP_DIR/sshd_config.backup" /etc/ssh/sshd_config
            fi
        fi
    fi
fi

# ============================================================================
# SECTION 7: System Configuration
# ============================================================================
DO_SYSCONFIG=false
case "$PRESET_MODE" in
    standard|full) DO_SYSCONFIG=true ;;
    interactive) ask_yes_no "Configure system settings (swap, timezone)?" "y" && DO_SYSCONFIG=true ;;
esac

if [ "$DO_SYSCONFIG" = true ]; then
    echo ""
    print_header "System Configuration"

    # Check and create swap if needed
    SWAP_EXISTS=$(swapon --show | wc -l)
    if [ "$SWAP_EXISTS" -eq 0 ]; then
        print_info "No swap detected"
        CREATE_SWAP=false

        if [ "$INTERACTIVE" = true ]; then
            ask_yes_no "Create 2GB swap file?" "y" && CREATE_SWAP=true
        else
            CREATE_SWAP=true
        fi

        if [ "$CREATE_SWAP" = true ] && [ "$DRY_RUN" = false ]; then
            print_info "Creating 2GB swap file..."
            sudo fallocate -l 2G /swapfile
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon /swapfile
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
            print_success "Swap file created and enabled"
        fi
    else
        print_success "Swap already configured"
    fi

    # Set timezone (interactive only)
    if [ "$INTERACTIVE" = true ]; then
        CURRENT_TZ=$(timedatectl show --property=Timezone --value)
        print_info "Current timezone: $CURRENT_TZ"

        if ask_yes_no "Change timezone?" "n"; then
            echo ""
            echo "Available timezones (examples):"
            echo "  America/New_York, America/Los_Angeles, America/Chicago"
            echo "  Europe/London, Europe/Paris, Europe/Berlin"
            echo "  Asia/Tokyo, Asia/Shanghai, Asia/Dubai"
            echo ""
            read -rp "Enter timezone: " NEW_TZ
            if [ -n "$NEW_TZ" ]; then
                execute_or_simulate sudo timedatectl set-timezone "$NEW_TZ"
                print_success "Timezone set to $NEW_TZ"
            fi
        fi
    fi
fi

# ============================================================================
# SECTION 8: User Experience Improvements
# ============================================================================
DO_UX=false
case "$PRESET_MODE" in
    standard|full) DO_UX=true ;;
    interactive) ask_yes_no "Add useful bash aliases and improvements?" "y" && DO_UX=true ;;
esac

if [ "$DO_UX" = true ]; then
    echo ""
    print_header "User Experience Improvements"

    if [ "$DRY_RUN" = false ]; then
        backup_file "$HOME/.bashrc"

        # Add useful aliases and settings
        cat >> "$HOME/.bashrc" <<'EOF'

# ============ System Maintenance Aliases ============
alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean'
alias sysinfo='echo "=== System Info ===" && lsb_release -a && echo && df -h && echo && free -h'

# ============ Useful Aliases ============
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias ports='netstat -tulanp'
alias meminfo='free -m -l -t'
alias psmem='ps auxf | sort -nr -k 4 | head -10'
alias pscpu='ps auxf | sort -nr -k 3 | head -10'

# ============ History Settings ============
export HISTTIMEFORMAT="%F %T "
export HISTSIZE=10000
export HISTFILESIZE=20000
shopt -s histappend

# ============ Better ls colors ============
export LS_COLORS='di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

EOF

        print_success "Bash improvements added to ~/.bashrc"
        print_info "Restart your terminal or run: source ~/.bashrc"
    fi
fi

# ============================================================================
# SECTION 9: Disable Unnecessary Services (Optional)
# ============================================================================
DO_DISABLE_SERVICES=false
case "$PRESET_MODE" in
    full)
        if [ "$INTERACTIVE" = true ]; then
            ask_yes_no "Disable unnecessary services (bluetooth, cups)?" "n" && DO_DISABLE_SERVICES=true
        fi
        ;;
    interactive) ask_yes_no "Disable unnecessary services (bluetooth, cups)?" "n" && DO_DISABLE_SERVICES=true ;;
esac

if [ "$DO_DISABLE_SERVICES" = true ]; then
    echo ""
    print_header "Disabling Unnecessary Services"

    # Bluetooth
    if systemctl is-enabled bluetooth &>/dev/null; then
        if ask_yes_no "Disable bluetooth?" "y"; then
            execute_or_simulate sudo systemctl stop bluetooth
            execute_or_simulate sudo systemctl disable bluetooth
            print_success "Bluetooth disabled"
        fi
    fi

    # CUPS (printing)
    if systemctl is-enabled cups &>/dev/null; then
        if ask_yes_no "Disable CUPS (printing)?" "y"; then
            execute_or_simulate sudo systemctl stop cups
            execute_or_simulate sudo systemctl disable cups
            print_success "CUPS disabled"
        fi
    fi
fi

# ============================================================================
# Final Summary
# ============================================================================
echo ""
print_header "Initialization Complete!"

if [ "$DRY_RUN" = true ]; then
    print_info "DRY RUN complete - no changes were made"
    print_info "Run without --dry-run to apply changes"
else
    print_success "System initialization completed successfully"

    if [ -d "$BACKUP_DIR" ]; then
        echo ""
        print_info "Configuration backups saved to:"
        echo -e "${DIM}  $BACKUP_DIR${NC}"
    fi
fi

echo ""
print_info "System Information:"
echo -e "${DIM}  ├─ Distribution: $(lsb_release -ds)${NC}"
echo -e "${DIM}  ├─ Kernel: $(uname -r)${NC}"
echo -e "${DIM}  └─ Initialized: $(date)${NC}"

echo ""
print_info "Next steps:"
echo -e "${DIM}  1. Restart your terminal: source ~/.bashrc${NC}"
echo -e "${DIM}  2. Review firewall rules: sudo ufw status verbose${NC}"
echo -e "${DIM}  3. Test SSH access (if configured) before closing session${NC}"
echo -e "${DIM}  4. Run ./update.sh to ensure system is up to date${NC}"
echo -e "${DIM}  5. Consider rebooting: sudo reboot${NC}"

if [ "$ENABLE_LOGGING" = true ]; then
    echo ""
    print_info "Full log saved to: ${LOG_FILE}"
fi

if [ "$ERRORS_OCCURRED" = true ]; then
    echo ""
    print_warning "Some operations encountered errors (see above)"
    exit 1
fi

echo ""
