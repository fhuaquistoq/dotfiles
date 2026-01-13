#!/usr/bin/env bash

# ==============================================
# Uninstall Script
# ==============================================
# Remove dotfiles and restore backups
# ==============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_header "Dotfiles Uninstaller"

echo -e "${RED}WARNING: This will remove all dotfiles configurations!${NC}"
echo -e "Configs to be removed:"
echo "  - ~/.config/fish"
echo "  - ~/.config/kitty"
echo "  - ~/.config/hypr"
echo "  - ~/.config/sway"
echo "  - ~/.config/waybar"
echo "  - ~/.config/dunst"
echo "  - ~/.config/mise"
echo "  - ~/.config/starship.toml"
echo ""

read -p "Are you sure you want to continue? [y/N]: " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Find most recent backup
BACKUP_DIR=$(ls -dt ~/.config-backup-* 2>/dev/null | head -1)

if [[ -n "$BACKUP_DIR" ]]; then
    echo -e "\n${GREEN}Found backup: $BACKUP_DIR${NC}"
    read -p "Restore from this backup? [Y/n]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_info "Restoring backup..."
        
        # Remove current configs
        rm -rf ~/.config/fish
        rm -rf ~/.config/kitty
        rm -rf ~/.config/hypr
        rm -rf ~/.config/sway
        rm -rf ~/.config/waybar
        rm -rf ~/.config/dunst
        rm -rf ~/.config/mise
        rm -f ~/.config/starship.toml
        
        # Restore backup
        cp -r "$BACKUP_DIR"/* ~/.config/
        
        print_info "Backup restored successfully!"
    fi
else
    print_warning "No backup found. Removing configs without restore."
    
    read -p "Continue? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.config/fish
        rm -rf ~/.config/kitty
        rm -rf ~/.config/hypr
        rm -rf ~/.config/sway
        rm -rf ~/.config/waybar
        rm -rf ~/.config/dunst
        rm -rf ~/.config/mise
        rm -f ~/.config/starship.toml
        
        print_info "Configs removed."
    fi
fi

echo -e "\n${GREEN}Uninstallation complete!${NC}"
echo "Note: Packages were not removed. Use pacman/paru manually if needed."
