#!/usr/bin/env bash

# ==============================================
# Dotfiles Installation Script for Arch Linux
# ==============================================
# This script automates the installation of
# dotfiles and all required packages
# ==============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/packages"

# ==============================================
# Helper Functions
# ==============================================

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    read -p "$prompt" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY && "$default" == "y" ]]; then
        return 0
    else
        return 1
    fi
}

install_packages() {
    local package_file="$1"
    local description="$2"
    
    if [[ ! -f "$package_file" ]]; then
        print_error "Package file not found: $package_file"
        return 1
    fi
    
    print_info "Installing $description..."
    
    # Read packages from file, skip comments and empty lines
    local packages=$(grep -v '^#' "$package_file" | grep -v '^$' | tr '\n' ' ')
    
    if [[ -n "$packages" ]]; then
        sudo pacman -S --needed --noconfirm $packages
    fi
}

install_aur_packages() {
    local package_file="$1"
    
    if [[ ! -f "$package_file" ]]; then
        print_error "Package file not found: $package_file"
        return 1
    fi
    
    print_info "Installing AUR packages..."
    
    # Read packages from file, skip comments and empty lines
    local packages=$(grep -v '^#' "$package_file" | grep -v '^$' | tr '\n' ' ')
    
    if [[ -n "$packages" ]]; then
        paru -S --needed --noconfirm $packages
    fi
}

# ==============================================
# Pre-installation Checks
# ==============================================

print_header "Pre-installation Checks"

# Check if running on Arch Linux
if [[ ! -f /etc/arch-release ]]; then
    print_error "This script is designed for Arch Linux only!"
    exit 1
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "Do not run this script as root!"
    exit 1
fi

print_info "Running on Arch Linux ✓"
print_info "Running as regular user ✓"

# ==============================================
# Enable Multilib Repository
# ==============================================

print_header "Enabling Multilib Repository"

if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    print_info "Enabling multilib repository..."
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    print_info "Multilib enabled ✓"
else
    print_info "Multilib already enabled ✓"
fi

# Update package database
print_info "Updating package database..."
sudo pacman -Sy

# ==============================================
# Install Graphics Drivers
# ==============================================

print_header "Graphics Drivers Selection"

echo "Select your graphics card:"
echo "1) Intel"
echo "2) Nvidia"
echo "3) Intel + Nvidia (Hybrid)"
echo "4) None (Skip driver installation)"
read -p "Enter option [1-4]: " GPU_OPTION

case $GPU_OPTION in
    1)
        print_info "Installing Intel graphics drivers..."
        install_packages "$PACKAGES_DIR/gpu-intel.txt" "Intel graphics drivers"
        print_info "Intel drivers installed ✓"
        ;;
    2)
        echo -e "\nSelect Nvidia driver type:"
        echo "1) Proprietary (Better performance, NOT compatible with Sway)"
        echo "2) Nouveau (Open source, compatible with Sway and Hyprland)"
        read -p "Enter option [1-2]: " NVIDIA_TYPE
        
        case $NVIDIA_TYPE in
            1)
                print_info "Installing Nvidia proprietary drivers..."
                install_packages "$PACKAGES_DIR/gpu-nvidia-proprietary.txt" "Nvidia proprietary drivers"
                print_info "Nvidia proprietary drivers installed ✓"
                print_warning "⚠️  IMPORTANT: Sway compositor will NOT work with proprietary Nvidia drivers!"
                print_warning "⚠️  Use Hyprland instead, or reinstall with Nouveau drivers."
                print_warning "⚠️  You may need to reboot after installation for drivers to work properly!"
                ;;
            2)
                print_info "Installing Nvidia Nouveau drivers..."
                install_packages "$PACKAGES_DIR/gpu-nvidia-nouveau.txt" "Nvidia Nouveau drivers"
                print_info "Nvidia Nouveau drivers installed ✓"
                ;;
            *)
                print_warning "Invalid option. Skipping Nvidia driver installation."
                ;;
        esac
        ;;
    3)
        print_info "Installing Intel graphics drivers..."
        install_packages "$PACKAGES_DIR/gpu-intel.txt" "Intel graphics drivers"
        
        echo -e "\nSelect Nvidia driver type for hybrid setup:"
        echo "1) Proprietary (Better performance, NOT compatible with Sway)"
        echo "2) Nouveau (Open source, compatible with Sway and Hyprland)"
        read -p "Enter option [1-2]: " NVIDIA_TYPE
        
        case $NVIDIA_TYPE in
            1)
                print_info "Installing Nvidia proprietary drivers..."
                install_packages "$PACKAGES_DIR/gpu-nvidia-proprietary.txt" "Nvidia proprietary drivers"
                print_info "Hybrid graphics drivers installed ✓"
                print_warning "⚠️  IMPORTANT: Sway compositor will NOT work with proprietary Nvidia drivers!"
                print_warning "⚠️  Use Hyprland instead, or reinstall with Nouveau drivers."
                print_warning "⚠️  You may need to reboot after installation for drivers to work properly!"
                ;;
            2)
                print_info "Installing Nvidia Nouveau drivers..."
                install_packages "$PACKAGES_DIR/gpu-nvidia-nouveau.txt" "Nvidia Nouveau drivers"
                print_info "Hybrid graphics drivers installed ✓"
                ;;
            *)
                print_warning "Invalid option. Skipping Nvidia driver installation."
                ;;
        esac
        ;;
    4)
        print_info "Skipping graphics driver installation"
        ;;
    *)
        print_warning "Invalid option. Skipping graphics driver installation."
        ;;
esac

# ==============================================
# Install Essential Packages
# ==============================================

print_header "Installing Essential Packages"

if ask_yes_no "Install essential system packages?"; then
    install_packages "$PACKAGES_DIR/essential.txt" "essential packages"
fi

# ==============================================
# Enable NetworkManager
# ==============================================

print_header "Enabling NetworkManager"

if ask_yes_no "Enable NetworkManager service?"; then
    print_info "Enabling NetworkManager..."
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager || true
    print_info "NetworkManager enabled ✓"
fi

# ==============================================
# Install Desktop Environment Packages
# ==============================================

print_header "Installing Desktop Environment"

if ask_yes_no "Install desktop environment packages?"; then
    install_packages "$PACKAGES_DIR/desktop.txt" "desktop packages"
fi

# ==============================================
# Install Fonts
# ==============================================

print_header "Installing Fonts"

if ask_yes_no "Install fonts?"; then
    install_packages "$PACKAGES_DIR/fonts.txt" "fonts"
fi

# ==============================================
# Install Shell & CLI Tools
# ==============================================

print_header "Installing Shell & CLI Tools"

if ask_yes_no "Install shell and CLI tools?"; then
    install_packages "$PACKAGES_DIR/shell.txt" "shell tools"
fi

# ==============================================
# Install Development Tools
# ==============================================

print_header "Installing Development Tools"

if ask_yes_no "Install development tools?"; then
    install_packages "$PACKAGES_DIR/development.txt" "development packages"
fi

# ==============================================
# Install Applications
# ==============================================

print_header "Installing User Applications"

if ask_yes_no "Install user applications?"; then
    install_packages "$PACKAGES_DIR/applications.txt" "applications"
fi

# ==============================================
# Install Paru (AUR Helper)
# ==============================================

print_header "Installing Paru (AUR Helper)"

if ! command -v paru &> /dev/null; then
    if ask_yes_no "Install paru (AUR helper)?"; then
        print_info "Installing paru..."
        cd /tmp
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
        print_info "Paru installed ✓"
    fi
else
    print_info "Paru already installed ✓"
fi

# ==============================================
# Install AUR Packages
# ==============================================

if command -v paru &> /dev/null; then
    print_header "Installing AUR Packages"
    
    if ask_yes_no "Install AUR packages?"; then
        install_aur_packages "$PACKAGES_DIR/aur.txt"
    fi
fi

# ==============================================
# Install Mise (Version Manager)
# ==============================================

print_header "Installing Mise"

if ! command -v mise &> /dev/null; then
    if ask_yes_no "Install mise (development version manager)?"; then
        print_info "Installing mise..."
        curl https://mise.run | sh
        print_info "Mise installed ✓"
    fi
else
    print_info "Mise already installed ✓"
fi

# ==============================================
# Install Zed Editor (Optional)
# ==============================================

print_header "Installing Zed Editor"

if ! command -v zed &> /dev/null; then
    if ask_yes_no "Install Zed editor?" "n"; then
        print_info "Installing Zed..."
        curl -f https://zed.dev/install.sh | sh
        print_info "Zed installed ✓"
    fi
else
    print_info "Zed already installed ✓"
fi

# ==============================================
# Install Fish Plugins
# ==============================================

print_header "Installing Fish Shell Plugins"

if command -v fish &> /dev/null; then
    if ask_yes_no "Install Fish shell plugins?"; then
        print_info "Installing Fisher plugin manager..."
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
        
        if [[ -f "$SCRIPT_DIR/fish/fish_plugins" ]]; then
            print_info "Installing Fish plugins from fish_plugins file..."
            fish -c "fisher update"
        fi
        
        print_info "Fish plugins installed ✓"
    fi
fi

# ==============================================
# Enable Docker
# ==============================================

print_header "Configuring Docker"

if command -v docker &> /dev/null; then
    if ask_yes_no "Enable Docker service and add user to docker group?"; then
        print_info "Enabling Docker..."
        sudo systemctl enable docker
        sudo systemctl start docker || true
        sudo usermod -aG docker "$USER"
        print_info "Docker enabled ✓"
        print_warning "You need to log out and log back in for docker group changes to take effect!"
    fi
fi

# ==============================================
# Deploy Dotfiles
# ==============================================

print_header "Deploying Dotfiles"

if ask_yes_no "Deploy dotfiles to ~/.config?"; then
    print_info "Creating backup of existing configs..."
    BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # List of config directories to deploy
    CONFIGS=("fish" "kitty" "hypr" "sway" "waybar" "dunst" "starship.toml" "mise" "environment.d")
    
    for config in "${CONFIGS[@]}"; do
        if [[ -e "$HOME/.config/$config" ]]; then
            print_info "Backing up existing $config..."
            mv "$HOME/.config/$config" "$BACKUP_DIR/"
        fi
        
        if [[ -e "$SCRIPT_DIR/$config" ]]; then
            print_info "Deploying $config..."
            cp -r "$SCRIPT_DIR/$config" "$HOME/.config/"
        fi
    done
    
    # Copy misc scripts
    if [[ -d "$SCRIPT_DIR/misc/bin" ]]; then
        print_info "Deploying scripts to ~/.local/bin..."
        mkdir -p "$HOME/.local/bin"
        cp -r "$SCRIPT_DIR/misc/bin/"* "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/"*
    fi
    
    print_info "Dotfiles deployed ✓"
    print_info "Backup saved to: $BACKUP_DIR"
fi

# ==============================================
# Configure SDDM
# ==============================================

print_header "Configuring SDDM"

if command -v sddm &> /dev/null; then
    if ask_yes_no "Install SDDM Pixel theme?"; then
        if [[ -d "$SCRIPT_DIR/sddm/sddm-pixel" ]]; then
            print_info "Installing SDDM Pixel theme..."
            cd "$SCRIPT_DIR/sddm/sddm-pixel"
            sudo bash setup.sh
            print_info "SDDM theme installed ✓"
        else
            print_warning "SDDM theme directory not found!"
        fi
    fi
    
    if ask_yes_no "Enable SDDM service?"; then
        print_info "Enabling SDDM..."
        sudo systemctl enable sddm
        print_info "SDDM enabled ✓"
    fi
fi

# ==============================================
# Post-Installation
# ==============================================

print_header "Installation Complete!"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Installation completed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Log out and log back in (for group changes to take effect)"
echo "2. If you installed mise, run: mise install (in your project directories)"
echo "3. Select Hyprland or Sway session from your display manager"
echo "4. Enjoy your new setup!"

echo -e "\n${YELLOW}Optional Steps:${NC}"
echo "- Configure your monitors in hypr/hyprland.conf.d/monitors.conf"
echo "- Set your wallpaper with: waypaper"
echo "- Customize themes in the respective theme directories"
echo "- Review the README.md for more information"

echo -e "\n${BLUE}Thank you for using these dotfiles!${NC}\n"
