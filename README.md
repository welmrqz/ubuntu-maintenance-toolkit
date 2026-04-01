# Ubuntu System Maintenance Scripts

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A collection of safe, comprehensive scripts for maintaining and updating Ubuntu 24.04+ systems.

## Overview

This repository provides three comprehensive maintenance scripts covering the complete system lifecycle:

- **initialize.sh** - First-time system setup with security hardening and essential configuration
- **update.sh** - Comprehensive system update script covering APT, Snap, Flatpak, firmware, and development tools
- **cleanup.sh** - Safe disk cleanup script with dry-run mode and aggressive cleanup options

All scripts feature:
- Beautiful terminal output with color-coded status indicators
- Comprehensive error handling and safety checks
- Preview/dry-run modes to see changes before applying
- Detailed logging with timestamps
- Interactive and non-interactive modes
- Progress tracking

## Scripts

### initialize.sh

First-time system initialization script for new Ubuntu installations with security hardening and best practices.

**What it configures:**

**Security Hardening:**
- UFW firewall configuration (deny incoming, allow outgoing)
- Automatic security updates (unattended-upgrades)
- fail2ban for SSH brute-force protection
- SSH hardening (disable root login, key-only auth)

**System Configuration:**
- Swap file creation (if not present)
- Timezone configuration
- Essential system utilities
- Development tools (optional)

**User Experience:**
- Useful bash aliases and shortcuts
- Improved history settings
- Better terminal colors
- System maintenance aliases

**Features:**
- Three preset modes: minimal, standard, full
- Interactive mode with questions for each section
- Dry-run mode to preview changes
- Automatic backups of modified config files
- Safe, idempotent (can run multiple times)
- Ubuntu version detection

**Usage:**

```bash
# Interactive mode (recommended for first use)
./initialize.sh

# Minimal security hardening only
./initialize.sh --minimal

# Standard setup (recommended for most users)
./initialize.sh --standard

# Full setup including dev tools
./initialize.sh --full

# Preview what would be done
./initialize.sh --dry-run

# Non-interactive with standard preset
./initialize.sh --standard --non-interactive

# Show help
./initialize.sh --help
```

**Preset Modes:**

| Mode | Security | Utilities | Dev Tools | SSH Hardening | UX Improvements |
|------|----------|-----------|-----------|---------------|-----------------|
| `--minimal` | ✓ | ✗ | ✗ | ✗ | ✗ |
| `--standard` | ✓ | ✓ | ✗ | ✗ | ✓ |
| `--full` | ✓ | ✓ | ✓ | ✓ | ✓ |
| Interactive | Ask each | Ask each | Ask each | Ask each | Ask each |

**Options:**

| Option | Description |
|--------|-------------|
| `--minimal` | Critical security only (UFW, fail2ban, auto-updates) |
| `--standard` | Security + common tools + basic config (recommended) |
| `--full` | Everything including dev tools and SSH hardening |
| `--non-interactive` | Run without prompts (uses defaults) |
| `--dry-run` | Show what would be done without doing it |
| `--no-log` | Disable logging to file |
| `--help` | Show usage information |

**What Gets Installed:**

*Essential Utilities (standard/full):*
- curl, wget, git, vim
- htop, ncdu, tree
- net-tools, dnsutils
- zip, unzip

*Development Tools (full only):*
- build-essential, make, cmake
- libssl-dev, pkg-config
- python3-pip, python3-venv

**Important Notes:**

- Always run `initialize.sh --dry-run` first to preview changes
- If enabling SSH hardening, ensure you have SSH keys set up
- Firewall will automatically allow SSH if SSH service is running
- Config backups are saved to `~/.config-backups-<timestamp>/`
- Safe to run multiple times (idempotent)

**Logs Location:** `~/.local/share/system-init-logs/initialize-YYYYMMDD-HHMMSS.log`

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
   chmod +x initialize.sh update.sh cleanup.sh
   ```

3. (Optional) Create symbolic links for easy access:
   ```bash
   sudo ln -s "$(pwd)/initialize.sh" /usr/local/bin/system-init
   sudo ln -s "$(pwd)/update.sh" /usr/local/bin/system-update
   sudo ln -s "$(pwd)/cleanup.sh" /usr/local/bin/system-cleanup
   ```

   Then you can run from anywhere:
   ```bash
   system-init
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

### First-Time Setup (New Installation)
```bash
# Preview what will be configured
./initialize.sh --dry-run

# Run interactive setup (recommended)
./initialize.sh

# Or use standard preset for quick setup
./initialize.sh --standard

# Update system after initialization
./update.sh

# Reboot to apply all changes
sudo reboot
```

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

### Server Deployment (Automated)
```bash
# Minimal security hardening for servers
./initialize.sh --minimal --non-interactive

# Keep system updated
./update.sh --no-log

# Periodic cleanup
./cleanup.sh
```

## Safety Features

### initialize.sh Safety
- Backs up all config files before modification (saved to `~/.config-backups-*/`)
- Dry-run mode to preview all changes before applying
- Detects Ubuntu version and warns if not 24.04+
- Interactive mode asks before each major change
- Idempotent - safe to run multiple times without harm
- Tests SSH config before applying changes
- Automatically allows SSH if service is detected (prevents lockout)
- Provides rollback info for config changes
- Never makes destructive changes without confirmation

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

All scripts feature beautiful, informative terminal output:

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

### initialize.sh Issues

**"This script is designed for Ubuntu systems"**
- Script detected non-Ubuntu system. Only run on Ubuntu installations.

**Locked out after SSH hardening**
- SSH hardening requires SSH keys to be set up first
- Restore from backup: `sudo cp ~/.config-backups-*/sshd_config.backup /etc/ssh/sshd_config`
- Restart SSH: `sudo systemctl restart sshd`

**UFW blocking connections**
- Check rules: `sudo ufw status verbose`
- Allow specific port: `sudo ufw allow <port>`
- Disable temporarily: `sudo ufw disable`

**Want to undo changes**
- Config backups are in `~/.config-backups-<timestamp>/`
- Restore specific file: `sudo cp ~/.config-backups-*/filename.backup /path/to/original`

### update.sh Issues

**"Another package manager is running"**
Wait for other package operations to complete (e.g., Software Center, unattended-upgrades).

**Script fails with permission errors**
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

Contributions are welcome! Whether it's bug fixes, new features, or documentation improvements.

**Guidelines:**
- Keep scripts safe and non-destructive
- Test thoroughly on Ubuntu 24.04+
- Document new features in the README
- Maintain comprehensive error handling
- Keep terminal output clear and informative
- Follow existing code style and formatting

**How to contribute:**
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

**Ideas for contributions:**
- Support for additional package managers
- More cleanup targets (safely!)
- Performance improvements
- Better error messages
- Translations
- Additional development tool updates

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

You are free to:
- Use these scripts for personal or commercial purposes
- Modify and adapt them to your needs
- Distribute them to others
- Include them in your own projects

The only requirement is to include the original copyright notice and license.

## Changelog

### Version 1.0.0 (Current)
- **initialize.sh** - First-time setup script with security hardening
  - UFW firewall configuration
  - Automatic security updates (unattended-upgrades)
  - fail2ban for SSH protection
  - SSH hardening options
  - Essential utilities installation
  - Interactive and preset modes
  - Config file backups
- **update.sh** - Comprehensive system update script
  - `--check` mode to preview updates
  - Firmware update support (fwupd)
  - Old kernel cleanup
  - Rust/cargo update support
  - Comprehensive logging with timestamps
  - Error tracking and reporting
- **cleanup.sh** - Safe disk cleanup script
  - `--dry-run` and `--aggressive` modes
  - Safe operation (no dangerous `/tmp` deletion)
  - Snap old revision cleanup
  - Docker cleanup (aggressive mode)
  - Browser cache cleanup (aggressive mode)
  - Space tracking before/after
- **All scripts** - Beautiful terminal output with symbols and colors
