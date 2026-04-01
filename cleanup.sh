#!/bin/bash

# System Cleanup Script for Ubuntu 24.04+
# Usage: ./cleanup.sh [--dry-run] [--aggressive]

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
DRY_RUN=false
AGGRESSIVE=false
SPACE_FREED=0

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --aggressive)
            AGGRESSIVE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run      Show what would be cleaned without doing it"
            echo "  --aggressive   More aggressive cleanup (includes Docker, more caches)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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
}

print_info() {
    echo -e "${DIM}  ℹ $1${NC}"
}

print_skip() {
    echo -e "${DIM}⊘ $1${NC}"
}

# Get directory size in MB
get_size_mb() {
    local path="$1"
    if [ -e "$path" ]; then
        du -sm "$path" 2>/dev/null | cut -f1 || echo "0"
    else
        echo "0"
    fi
}

# Format bytes to human readable
format_size() {
    local size=$1
    if [ "$size" -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $size/1024}") GB"
    else
        echo "${size} MB"
    fi
}

# Execute or simulate command based on dry-run mode
execute_or_simulate() {
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would execute: $*"
    else
        "$@"
    fi
}

# Main script
print_header "System Cleanup Script for Ubuntu"

if [ "$DRY_RUN" = true ]; then
    print_warning "Running in DRY-RUN mode - no changes will be made"
    echo ""
fi

if [ "$AGGRESSIVE" = true ]; then
    print_warning "Running in AGGRESSIVE mode - more extensive cleanup"
    echo ""
fi

# Record initial disk usage
INITIAL_DISK=$(df / | tail -1 | awk '{print $3}')

echo -e "${BOLD}Initial Disk Usage:${NC}"
df -h / /home 2>/dev/null | grep -v "Filesystem" | while read -r line; do
    echo -e "${DIM}  $(echo "$line" | awk '{print $6": "$3" used / "$2" total ("$5" full)")')${NC}"
done
echo ""

# Step 1: APT cleanup
print_step "Cleaning APT package cache"

print_info "Removing unused packages and old kernels..."
BEFORE_APT=$(get_size_mb "/var/cache/apt")
execute_or_simulate sudo apt autoremove --purge -y
if [ "$DRY_RUN" = false ]; then
    print_success "Unused packages and old kernels removed"
fi

print_info "Cleaning APT cache..."
execute_or_simulate sudo apt autoclean
execute_or_simulate sudo apt clean
AFTER_APT=$(get_size_mb "/var/cache/apt")
FREED=$((BEFORE_APT - AFTER_APT))
if [ "$DRY_RUN" = false ] && [ "$FREED" -gt 0 ]; then
    print_success "APT cache cleaned - freed $(format_size $FREED)"
    SPACE_FREED=$((SPACE_FREED + FREED))
else
    print_success "APT cache cleaned"
fi

# Step 2: Snap cleanup
echo ""
print_step "Cleaning Snap packages"
if command -v snap &> /dev/null; then
    print_info "Removing old snap revisions..."
    SNAP_COUNT=0

    # List all snaps with multiple revisions
    if [ "$DRY_RUN" = false ]; then
        snap list --all | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
            sudo snap remove "$snapname" --revision="$revision" 2>/dev/null && ((SNAP_COUNT++)) || true
        done
        if [ "$SNAP_COUNT" -gt 0 ]; then
            print_success "Removed $SNAP_COUNT old snap revision(s)"
        else
            print_success "No old snap revisions to remove"
        fi
    else
        SNAP_COUNT=$(snap list --all | grep -c "disabled" || true)
        print_info "[DRY RUN] Would remove $SNAP_COUNT old snap revision(s)"
    fi
else
    print_skip "Snap not installed"
fi

# Step 3: Flatpak cleanup
echo ""
print_step "Cleaning Flatpak data"
if command -v flatpak &> /dev/null; then
    print_info "Removing unused flatpak runtimes..."
    execute_or_simulate flatpak uninstall --unused -y
    print_success "Flatpak cleanup completed"
else
    print_skip "Flatpak not installed"
fi

# Step 4: Journal logs
echo ""
print_step "Cleaning system logs"
BEFORE_JOURNAL=$(get_size_mb "/var/log/journal")
print_info "Keeping only last 3 days of journal logs..."
execute_or_simulate sudo journalctl --vacuum-time=3d
AFTER_JOURNAL=$(get_size_mb "/var/log/journal")
FREED=$((BEFORE_JOURNAL - AFTER_JOURNAL))
if [ "$DRY_RUN" = false ] && [ "$FREED" -gt 0 ]; then
    print_success "Journal logs cleaned - freed $(format_size $FREED)"
    SPACE_FREED=$((SPACE_FREED + FREED))
else
    print_success "Journal logs cleaned"
fi

# Step 5: User caches
echo ""
print_step "Cleaning user cache files"

# Thumbnail cache
THUMB_SIZE=$(get_size_mb "$HOME/.cache/thumbnails")
if [ "$THUMB_SIZE" -gt 0 ]; then
    print_info "Clearing thumbnail cache ($THUMB_SIZE MB)..."
    execute_or_simulate rm -rf "$HOME/.cache/thumbnails/*"
    if [ "$DRY_RUN" = false ]; then
        print_success "Thumbnail cache cleared - freed $(format_size $THUMB_SIZE)"
        SPACE_FREED=$((SPACE_FREED + THUMB_SIZE))
    fi
else
    print_skip "Thumbnail cache is empty"
fi

# Browser caches (if aggressive mode)
if [ "$AGGRESSIVE" = true ]; then
    # Firefox cache
    if [ -d "$HOME/.cache/mozilla" ]; then
        FIREFOX_SIZE=$(get_size_mb "$HOME/.cache/mozilla")
        print_info "Clearing Firefox cache ($FIREFOX_SIZE MB)..."
        execute_or_simulate rm -rf "$HOME/.cache/mozilla/firefox/*/cache2/*"
        if [ "$DRY_RUN" = false ] && [ "$FIREFOX_SIZE" -gt 0 ]; then
            print_success "Firefox cache cleared"
            SPACE_FREED=$((SPACE_FREED + FIREFOX_SIZE))
        fi
    fi

    # Chromium/Chrome cache
    for cache_dir in "$HOME/.cache/google-chrome" "$HOME/.cache/chromium"; do
        if [ -d "$cache_dir" ]; then
            CHROME_SIZE=$(get_size_mb "$cache_dir")
            print_info "Clearing $(basename "$cache_dir") cache ($CHROME_SIZE MB)..."
            execute_or_simulate rm -rf "$cache_dir/Default/Cache/*"
            if [ "$DRY_RUN" = false ] && [ "$CHROME_SIZE" -gt 0 ]; then
                print_success "Browser cache cleared"
                SPACE_FREED=$((SPACE_FREED + CHROME_SIZE))
            fi
        fi
    done
fi

# Step 6: Trash cleanup
echo ""
print_step "Cleaning trash/recycle bin"
if [ -d "$HOME/.local/share/Trash" ]; then
    TRASH_SIZE=$(get_size_mb "$HOME/.local/share/Trash")
    if [ "$TRASH_SIZE" -gt 10 ]; then
        print_info "Emptying trash ($TRASH_SIZE MB)..."
        execute_or_simulate rm -rf "$HOME/.local/share/Trash/files/*"
        execute_or_simulate rm -rf "$HOME/.local/share/Trash/info/*"
        if [ "$DRY_RUN" = false ]; then
            print_success "Trash emptied - freed $(format_size $TRASH_SIZE)"
            SPACE_FREED=$((SPACE_FREED + TRASH_SIZE))
        fi
    else
        print_skip "Trash is already small ($TRASH_SIZE MB)"
    fi
else
    print_skip "No trash directory found"
fi

# Step 7: Docker cleanup (aggressive mode)
if [ "$AGGRESSIVE" = true ]; then
    echo ""
    print_step "Cleaning Docker data"
    if command -v docker &> /dev/null; then
        print_info "Removing unused Docker images, containers, and volumes..."
        if [ "$DRY_RUN" = false ]; then
            DOCKER_BEFORE=$(docker system df -v 2>/dev/null | grep "Total" | awk '{print $4}' | sed 's/GB//' || echo "0")
            sudo docker system prune -a --volumes -f &>/dev/null || true
            DOCKER_AFTER=$(docker system df -v 2>/dev/null | grep "Total" | awk '{print $4}' | sed 's/GB//' || echo "0")
            print_success "Docker cleanup completed"
        else
            print_info "[DRY RUN] Would run: docker system prune -a --volumes -f"
        fi
    else
        print_skip "Docker not installed"
    fi
fi

# Step 8: Old log files
echo ""
print_step "Cleaning old log files"
OLD_LOGS=$(find /var/log -type f -name "*.gz" -o -name "*.old" 2>/dev/null | wc -l || echo "0")
if [ "$OLD_LOGS" -gt 0 ]; then
    print_info "Removing $OLD_LOGS old compressed log files..."
    execute_or_simulate sudo find /var/log -type f \( -name "*.gz" -o -name "*.old" \) -delete
    if [ "$DRY_RUN" = false ]; then
        print_success "Old log files removed"
    fi
else
    print_skip "No old log files found"
fi

# Step 9: Package manager caches
if [ "$AGGRESSIVE" = true ]; then
    echo ""
    print_step "Cleaning additional package manager caches"

    # pip cache
    if command -v pip3 &> /dev/null; then
        PIP_SIZE=$(get_size_mb "$HOME/.cache/pip")
        if [ "$PIP_SIZE" -gt 50 ]; then
            print_info "Clearing pip cache ($PIP_SIZE MB)..."
            execute_or_simulate pip3 cache purge
            if [ "$DRY_RUN" = false ]; then
                print_success "pip cache cleared"
                SPACE_FREED=$((SPACE_FREED + PIP_SIZE))
            fi
        fi
    fi

    # npm cache
    if command -v npm &> /dev/null; then
        print_info "Cleaning npm cache..."
        execute_or_simulate npm cache clean --force
        print_success "npm cache cleaned"
    fi

    # cargo cache
    if [ -d "$HOME/.cargo/registry" ]; then
        CARGO_SIZE=$(get_size_mb "$HOME/.cargo/registry")
        if [ "$CARGO_SIZE" -gt 100 ]; then
            print_info "Cargo cache is large ($CARGO_SIZE MB)"
            print_info "Consider running: cargo cache -a"
        fi
    fi
fi

# Final summary
echo ""
print_header "Cleanup Summary"

# Calculate final disk usage
FINAL_DISK=$(df / | tail -1 | awk '{print $3}')
TOTAL_FREED=$(((INITIAL_DISK - FINAL_DISK) / 1024))

echo -e "${BOLD}Final Disk Usage:${NC}"
df -h / /home 2>/dev/null | grep -v "Filesystem" | while read -r line; do
    echo -e "${DIM}  $(echo "$line" | awk '{print $6": "$3" used / "$2" total ("$5" full)">')${NC}"
done

echo ""
if [ "$DRY_RUN" = false ]; then
    if [ "$TOTAL_FREED" -gt 0 ]; then
        print_success "Cleanup complete! Freed approximately $(format_size $TOTAL_FREED)"
    else
        print_success "Cleanup complete! System was already clean."
    fi
else
    print_info "DRY RUN complete - no changes were made"
    print_info "Run without --dry-run to perform actual cleanup"
fi

echo ""
print_info "Additional cleanup tips:"
echo -e "${DIM}  • Run with --aggressive for more thorough cleanup${NC}"
echo -e "${DIM}  • Check large files: ncdu / or du -sh /* | sort -h${NC}"
echo -e "${DIM}  • Find old files: find ~ -type f -atime +365 -size +100M${NC}"
echo ""
