#!/bin/bash
echo "Starting cleanup..."

# APT cleanup
sudo apt autoremove -y
sudo apt autoclean
sudo apt clean

# Journal logs (keep 3 days)
sudo journalctl --vacuum-time=3d

# Thumbnail cache
rm -rf ~/.cache/thumbnails/*

# Temp files
sudo rm -rf /tmp/*

# Check disk usage
df -h

echo "Cleanup complete!"
