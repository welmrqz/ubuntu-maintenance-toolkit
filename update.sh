#!/bin/bash

# System Update Script for Ubuntu 24.04
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}System Update Script${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""

# Check if running as root for system updates
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}Note: Some operations require sudo privileges${NC}"
    echo ""
fi

# Update APT packages
echo -e "${GREEN}[1/7] Updating APT package lists...${NC}"
sudo apt update

echo ""
echo -e "${GREEN}[2/7] Upgrading APT packages...${NC}"
sudo apt upgrade -y

echo ""
echo -e "${GREEN}[3/7] Running dist-upgrade...${NC}"
sudo apt dist-upgrade -y

echo ""
echo -e "${GREEN}[4/7] Removing unused packages...${NC}"
sudo apt autoremove -y
sudo apt autoclean

# Update Snap packages
echo ""
echo -e "${GREEN}[5/7] Updating Snap packages...${NC}"
if command -v snap &> /dev/null; then
    sudo snap refresh
else
    echo -e "${YELLOW}Snap not installed, skipping...${NC}"
fi

# Update Flatpak packages
echo ""
echo -e "${GREEN}[6/7] Updating Flatpak packages...${NC}"
if command -v flatpak &> /dev/null; then
    flatpak update -y
else
    echo -e "${YELLOW}Flatpak not installed, skipping...${NC}"
fi

# Update Deno
echo ""
echo -e "${GREEN}[7/7] Updating Deno...${NC}"
if command -v deno &> /dev/null; then
    deno upgrade
else
    echo -e "${YELLOW}Deno not installed, skipping...${NC}"
fi

# Cleanup
echo ""
echo -e "${GREEN}Cleaning up...${NC}"
sudo apt clean
sudo journalctl --vacuum-time=3d

# Summary
echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Update Complete!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo "System information:"
echo "-------------------"
lsb_release -d
uname -r
echo ""
echo -e "${YELLOW}A reboot may be required if the kernel was updated.${NC}"
echo "Check with: ls /var/run/reboot-required 2>/dev/null && cat /var/run/reboot-required.pkgs"
echo ""
