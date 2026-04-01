# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-04-01

### Added

#### initialize.sh
- First-time setup script with security hardening
- UFW firewall configuration
- Automatic security updates via unattended-upgrades
- fail2ban for SSH brute-force protection
- SSH hardening options (disable root login, key-only auth)
- Essential utilities installation
- Optional development tools installation
- Interactive and preset modes (`--minimal`, `--standard`, `--full`)
- Dry-run mode to preview changes before applying
- Automatic config file backups to `~/.config-backups-<timestamp>/`

#### update.sh
- Comprehensive system update script covering APT, Snap, Flatpak, firmware, and dev tools
- `--check` mode to preview updates without applying
- Firmware update support via fwupd
- Old kernel cleanup after updates
- Rust/Cargo toolchain update support
- Deno update support
- Comprehensive logging with timestamps
- Error tracking and summary reporting
- Lock file detection to prevent conflicts
- Reboot detection with package list

#### cleanup.sh
- Safe disk cleanup script
- `--dry-run` mode to preview all operations without making changes
- `--aggressive` mode for deeper cleanup
- Standard cleanup: APT cache, unused packages, old kernels, Snap old revisions, Flatpak unused runtimes, journal logs, thumbnails, trash, old compressed logs
- Aggressive cleanup: browser caches (Firefox, Chrome/Chromium), Docker images/containers/volumes, pip cache, npm cache
- Before/after disk usage comparison and per-operation size tracking
- Safe by design — no dangerous `/tmp` deletion

#### All Scripts
- Color-coded terminal output with status symbols (`▶`, `✓`, `⚠`, `✗`, `⊘`, `ℹ`)
- Non-interactive mode for automated/server use
- Logging with timestamps to `~/.local/share/`
