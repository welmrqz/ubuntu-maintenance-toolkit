# Ubuntu System Maintenance Scripts

A collection of safe, comprehensive scripts for maintaining and updating Ubuntu 24.04+ systems.

## Overview

This repository provides two main maintenance scripts:

- **update.sh** - Comprehensive system update script covering APT, Snap, Flatpak, firmware, and development tools
- **cleanup.sh** - Safe disk cleanup script with dry-run mode and aggressive cleanup options

Both scripts feature:
- Beautiful terminal output with color-coded status indicators
- Error handling and safety checks
- Preview/dry-run modes
- Detailed logging
- Progress tracking

## Scripts

### update.sh

Handles all system updates in one command, including:

- APT packages (update, upgrade, dist-upgrade)
- Old kernel removal
- Snap packages
- Flatpak packages
- Firmware updates (via fwupd)
- Development tools (Deno, Rust/Cargo)
- System cleanup after updates

**Features:**
- Lock file detection to prevent conflicts
- Shows upgradable packages before applying
- `--check` mode to preview updates
- Automatic logging with timestamps
- Reboot detection with package list
- Error tracking and reporting

**Usage:**

```bash
# Run full system update
./update.sh

# Preview updates without applying them
./update.sh --check

# Update without logging
./update.sh --no-log

# Show help
./update.sh --help
```

**Options:**

| Option | Description |
|--------|-------------|
| `--check` | Preview updates without applying changes |
| `--no-log` | Disable logging to file |
| `--help` | Show usage information |

**Logs Location:** `~/.local/share/system-update-logs/update-YYYYMMDD-HHMMSS.log`

### cleanup.sh

Safely cleans up disk space with intelligent detection and size tracking.

**What it cleans:**

**Standard mode:**
- APT package cache and unused packages
- Old kernel versions
- Snap old revisions (keeps latest only)
- Flatpak unused runtimes
- System journal logs (keeps 3 days)
- Thumbnail cache
- Trash/recycle bin (if >10MB)
- Old compressed log files

**Aggressive mode (--aggressive):**
- Everything from standard mode, plus:
- Browser caches (Firefox, Chrome/Chromium)
- Docker images, containers, and volumes
- pip cache (if >50MB)
- npm cache
- Cargo cache detection (with manual cleanup suggestion)

**Features:**
- `--dry-run` mode to preview without changes
- Before/after disk usage comparison
- Size tracking for each operation
- Safe by design (no risky `/tmp` deletion)
- Skips empty/small caches automatically

**Usage:**

```bash
# Run normal cleanup
./cleanup.sh

# Preview cleanup without making changes
./cleanup.sh --dry-run

# Aggressive cleanup (includes Docker, browsers, etc.)
./cleanup.sh --aggressive

# Dry-run aggressive mode
./cleanup.sh --dry-run --aggressive

# Show help
./cleanup.sh --help
```

**Options:**

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would be cleaned without doing it |
| `--aggressive` | More thorough cleanup (Docker, browsers, package managers) |
| `--help` | Show usage information |

## Installation

1. Clone or download this repository:
   ```bash
   cd ~/Projects
   git clone <repository-url> scripts-ubuntu
   cd scripts-ubuntu
   ```

2. Make scripts executable:
   ```bash
   chmod +x update.sh cleanup.sh
   ```

3. (Optional) Create symbolic links for easy access:
   ```bash
   sudo ln -s "$(pwd)/update.sh" /usr/local/bin/system-update
   sudo ln -s "$(pwd)/cleanup.sh" /usr/local/bin/system-cleanup
   ```

   Then you can run from anywhere:
   ```bash
   system-update
   system-cleanup
   ```

## Requirements

### Core Requirements
- Ubuntu 24.04 or later (may work on earlier versions)
- Bash shell
- sudo privileges
- `lsof` package (for lock detection)

### Optional Components
The scripts gracefully skip missing components:
- `snap` - for Snap package updates
- `flatpak` - for Flatpak updates
- `fwupd` - for firmware updates (install: `sudo apt install fwupd`)
- `deno` - for Deno updates
- `rustup` - for Rust toolchain updates
- `docker` - for Docker cleanup (aggressive mode)
- `pip3`, `npm`, `cargo` - for package manager cache cleanup (aggressive mode)

## Recommended Usage

### Weekly Maintenance
```bash
# Check what updates are available
./update.sh --check

# Apply updates
./update.sh

# Run cleanup
./cleanup.sh
```

### Monthly Deep Clean
```bash
# Update everything
./update.sh

# Aggressive cleanup
./cleanup.sh --aggressive
```

### Before Major Updates
```bash
# Preview what will be updated
./update.sh --check

# Free up space first
./cleanup.sh --aggressive

# Then update
./update.sh
```

## Safety Features

### update.sh Safety
- Checks for conflicting package managers before running
- Tracks errors and reports them at the end
- Uses `set -euo pipefail` for proper error handling
- Warns before dist-upgrade operations
- Detects when reboot is required
- Preserves full logs for troubleshooting

### cleanup.sh Safety
- **Never** deletes active temp files or system sockets
- Dry-run mode to preview all operations
- Size thresholds to avoid cleaning tiny caches
- Skips operations when tools aren't installed
- Shows exactly what will be freed before execution
- Preserves recent logs (3 days of journal)

## Terminal Output

Both scripts feature beautiful, informative terminal output:

```
╔════════════════════════════════════════════════════════════╗
║  System Update Script for Ubuntu
╚════════════════════════════════════════════════════════════╝

▶ [1/9] Updating APT package lists
✓ Package lists updated

▶ [2/9] Checking for package upgrades
✓ 15 packages can be upgraded
  ℹ Available upgrades:
    firefox/jammy-updates 121.0+build1-0ubuntu0.24.04.1
    ...

⚠ A system reboot is required!
✓ All updates completed successfully
```

Symbols used:
- `▶` - Step indicator
- `✓` - Success
- `⚠` - Warning
- `✗` - Error
- `⊘` - Skipped
- `ℹ` - Information

## Troubleshooting

### "Another package manager is running"
Wait for other package operations to complete (e.g., Software Center, unattended-upgrades).

### Script fails with permission errors
Ensure you have sudo privileges. The script will prompt for password when needed.

### Firmware updates not detected
Install fwupd: `sudo apt install fwupd`

### Cleanup not freeing expected space
- Try `--aggressive` mode for deeper cleanup
- Check for large files manually: `ncdu /` or `du -sh /* | sort -h`
- Old kernels may need manual review: `dpkg --list | grep linux-image`

### Logs taking up space
Update logs are stored in `~/.local/share/system-update-logs/`. Delete old logs:
```bash
find ~/.local/share/system-update-logs/ -type f -mtime +30 -delete
```

## Advanced Tips

### Find Large Files
```bash
# Find files larger than 100MB not accessed in a year
find ~ -type f -atime +365 -size +100M -exec ls -lh {} \;

# Use ncdu for interactive disk usage analysis
sudo apt install ncdu
ncdu /
```

### Schedule Automatic Updates
Add to crontab for weekly updates (Sundays at 3 AM):
```bash
crontab -e
# Add this line:
0 3 * * 0 /home/username/Projects/scripts-ubuntu/update.sh --no-log >> /var/log/auto-update.log 2>&1
```

### Monitor Disk Space
```bash
# Check disk usage
df -h

# Find what's using space
du -sh /* 2>/dev/null | sort -h

# Check specific directories
du -h --max-depth=1 /var/log | sort -h
```

### Docker Cleanup (Manual)
```bash
# Remove all stopped containers
docker container prune -f

# Remove unused images
docker image prune -a -f

# Remove unused volumes
docker volume prune -f

# Full cleanup
docker system prune -a --volumes -f
```

## Contributing

Suggestions and improvements are welcome! Please ensure:
- Scripts remain safe and non-destructive
- Features are well-documented
- Error handling is comprehensive
- Terminal output is clear and informative

## License

These scripts are provided as-is for system maintenance purposes. Use at your own discretion.

## Changelog

### Version 2.0 (Current)
- Complete rewrite with safety improvements
- Added `--check` and `--dry-run` modes
- Added firmware update support
- Removed dangerous `/tmp` deletion
- Added Snap old revision cleanup
- Added comprehensive logging
- Improved terminal output with symbols and colors
- Added error tracking and reporting
- Added Docker cleanup (aggressive mode)
- Added browser cache cleanup (aggressive mode)

### Version 1.0 (Initial)
- Basic update and cleanup functionality
