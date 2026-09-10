#!/bin/bash

# This runs inside the ISO build environment
# Set permissions for all scripts

# Make scripts executable (i3/polybar scripts have no .sh extension)
chmod +x /root/.config/i3/scripts/* 2>/dev/null
chmod +x /root/.config/polybar/launch.sh 2>/dev/null
chmod +x /usr/local/bin/* 2>/dev/null
find /root -name '*.sh' -exec chmod +x {} \; 2>/dev/null