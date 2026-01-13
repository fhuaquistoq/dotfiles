#!/bin/bash

# Setup script for SDDM Pixel Theme
# This script installs the theme and configures SDDM to use it
# Requires root/sudo privileges

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run with sudo${NC}"
    echo "Usage: sudo bash setup.sh"
    exit 1
fi

echo -e "${GREEN}=== SDDM Pixel Theme Setup ===${NC}"

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="sddm-pixel"
SDDM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_CONF="/etc/sddm.conf"
SDDM_CONF_D="/etc/sddm.conf.d"
VIRTUALKBD_CONF="${SDDM_CONF_D}/virtualkbd.conf"

echo -e "${YELLOW}→ Copying theme files...${NC}"
# Create the themes directory if it doesn't exist
mkdir -p "$SDDM_THEMES_DIR"

# Remove existing theme directory if it exists
if [ -e "${SDDM_THEMES_DIR}/${THEME_NAME}" ]; then
    echo "  Removing existing theme directory..."
    rm -rf "${SDDM_THEMES_DIR}/${THEME_NAME}"
fi

# Copy all files to the themes directory (excluding setup.sh)
echo "  Copying theme files from ${SCRIPT_DIR}..."
cp -r "$SCRIPT_DIR" "${SDDM_THEMES_DIR}/${THEME_NAME}"

# Remove setup.sh from the destination
rm -f "${SDDM_THEMES_DIR}/${THEME_NAME}/setup.sh"

echo -e "${GREEN}✓ Theme files copied to: ${SDDM_THEMES_DIR}/${THEME_NAME}${NC}"

echo -e "${YELLOW}→ Configuring SDDM...${NC}"

# Check if /etc/sddm.conf exists, if not create it
if [ ! -f "$SDDM_CONF" ]; then
    echo "  Creating /etc/sddm.conf..."
    cat > "$SDDM_CONF" << 'EOF'
[General]
Theme=sddm-pixel
EOF
else
    # Backup the original file
    echo "  Backing up original sddm.conf to sddm.conf.bak..."
    cp "$SDDM_CONF" "${SDDM_CONF}.bak"
    
    # Update or add the Theme setting
    if grep -q "^Theme=" "$SDDM_CONF"; then
        # Replace existing Theme line
        sed -i "s/^Theme=.*/Theme=sddm-pixel/" "$SDDM_CONF"
    else
        # Add Theme line under [General] section
        if grep -q "^\[General\]" "$SDDM_CONF"; then
            sed -i "/^\[General\]/a Theme=sddm-pixel" "$SDDM_CONF"
        else
            # No [General] section, add it
            echo "" >> "$SDDM_CONF"
            echo "[General]" >> "$SDDM_CONF"
            echo "Theme=sddm-pixel" >> "$SDDM_CONF"
        fi
    fi
fi

echo -e "${GREEN}✓ SDDM configured to use sddm-pixel theme${NC}"

echo -e "${YELLOW}→ Configuring virtual keyboard...${NC}"

# Create the sddm.conf.d directory if it doesn't exist
mkdir -p "$SDDM_CONF_D"

# Handle virtual keyboard configuration
# Since we want manual control (NOT auto-activation), we need to be careful with InputMethod
if [ -f "$VIRTUALKBD_CONF" ]; then
    echo "  Found existing virtualkbd.conf"
    
    # Check if InputMethod is set to qtvirtualkeyboard
    if grep -q "InputMethod=qtvirtualkeyboard" "$VIRTUALKBD_CONF"; then
        echo "  ⚠️  InputMethod is set to activate virtual keyboard automatically"
        echo "  Since the theme uses manual activation, removing auto-activation..."
        
        # Comment out or remove the InputMethod line
        sed -i 's/^InputMethod=qtvirtualkeyboard/#InputMethod=qtvirtualkeyboard/' "$VIRTUALKBD_CONF"
        
        echo -e "${GREEN}✓ Virtual keyboard set to manual activation${NC}"
    fi
else
    echo "  Creating ${VIRTUALKBD_CONF}..."
    mkdir -p "$SDDM_CONF_D"
    
    cat > "$VIRTUALKBD_CONF" << 'EOF'
# Virtual Keyboard Configuration
# This theme uses MANUAL virtual keyboard activation via the Virtual Keyboard button
# Do NOT set InputMethod=qtvirtualkeyboard as it would auto-activate on focus
# which defeats the purpose of manual control

[General]
# InputMethod=qtvirtualkeyboard
EOF
    
    echo -e "${GREEN}✓ Virtual keyboard configured for manual activation${NC}"
fi

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "Summary:"
echo "  ✓ Theme installed to: ${SDDM_THEMES_DIR}/${THEME_NAME}"
echo "  ✓ SDDM configured to use: sddm-pixel"
echo "  ✓ Virtual keyboard set to: Manual activation (via button)"
echo ""
echo "Next steps:"
echo "  1. Restart your system or restart SDDM to see the changes"
echo "  2. To restart SDDM without rebooting (on X11):"
echo "     sudo systemctl restart sddm"
echo ""
echo "Notes:"
echo "  • The virtual keyboard will NOT activate automatically on focus"
echo "  • Users must click the 'Virtual Keyboard' button to activate it"
echo "  • This is better for devices with physical keyboards"
echo ""
