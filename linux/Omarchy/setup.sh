#!/bin/bash
# Omarchy post-install customization.
# Run after a fresh Omarchy install to restore personal config.
#
# Prerequisites:
#   - Omarchy installed (https://omarchy.org)
#   - Internet connection
#   - ~/brain cloned (for Claude Code PAI symlinks)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$(uname -s)" = "Darwin" ]; then
    echo "This script is for Linux/Omarchy only."
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    echo "pacman not found. This script targets Arch/Omarchy."
    exit 1
fi

echo "=== Omarchy Post-Install Setup ==="

# --- yay (AUR helper) --------------------------------------------------------
if ! command -v yay >/dev/null 2>&1; then
    echo "Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
fi

# --- Extra packages (not in base Omarchy) ------------------------------------
echo "Installing extra packages..."
sudo pacman -S --needed --noconfirm \
    tmux \
    docker docker-buildx docker-compose \
    lazydocker lazygit \
    obs-studio \
    kdenlive \
    localsend \
    ollama-cuda \
    bat dust fd ripgrep fzf zoxide \
    python-poetry-core \
    ruby rust luarocks \
    postgresql-libs mariadb-libs

# AUR packages
yay -S --needed --noconfirm \
    google-chrome \
    wezterm-nightly-bin \
    visual-studio-code-bin \
    simplenote-electron-bin \
    signal-desktop \
    spotify \
    typora \
    obsidian \
    1password-beta 1password-cli \
    blesh-git \
    claude-code \
    mise \
    ttf-scheherazade-new \
    || true

# --- Deploy config files -----------------------------------------------------
echo ""
echo "Deploying configs..."

# Hyprland
cp "$SCRIPT_DIR/config/hypr/"*.conf "$HOME/.config/hypr/"
echo "  -> ~/.config/hypr/ (all configs)"

# Waybar
cp "$SCRIPT_DIR/config/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
cp "$SCRIPT_DIR/config/waybar/style.css" "$HOME/.config/waybar/style.css"
echo "  -> ~/.config/waybar/"

# WezTerm
mkdir -p "$HOME/.config/wezterm"
cp "$SCRIPT_DIR/config/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
echo "  -> ~/.config/wezterm/"

# Walker
cp "$SCRIPT_DIR/config/walker/config.toml" "$HOME/.config/walker/config.toml"
echo "  -> ~/.config/walker/"

# Micro
mkdir -p "$HOME/.config/micro"
cp "$SCRIPT_DIR/config/micro/settings.json" "$HOME/.config/micro/settings.json"
echo "  -> ~/.config/micro/"

# Git
mkdir -p "$HOME/.config/git"
cp "$SCRIPT_DIR/config/git/config" "$HOME/.config/git/config"
echo "  -> ~/.config/git/"

# Starship
cp "$SCRIPT_DIR/config/starship.toml" "$HOME/.config/starship.toml"
echo "  -> ~/.config/starship.toml"

# Bashrc
cp "$SCRIPT_DIR/.bashrc" "$HOME/.bashrc"
echo "  -> ~/.bashrc"

# Omarchy hooks
mkdir -p "$HOME/.config/omarchy/hooks"
cp "$SCRIPT_DIR/config/omarchy/hooks/theme-set" "$HOME/.config/omarchy/hooks/theme-set"
cp "$SCRIPT_DIR/config/omarchy/hooks/micro-theme-sync" "$HOME/.config/omarchy/hooks/micro-theme-sync"
chmod +x "$HOME/.config/omarchy/hooks/theme-set"
chmod +x "$HOME/.config/omarchy/hooks/micro-theme-sync"
echo "  -> ~/.config/omarchy/hooks/"

# --- Custom themes ------------------------------------------------------------
echo ""
echo "Installing custom themes..."
THEMES=(
    "https://github.com/hoblin/omarchy-cobalt2-theme"
    "https://github.com/Kushal0924/omarchy-gruvbox-light-theme"
    "https://github.com/ItsABigIgloo/omarchy-mapquest-theme"
    "https://github.com/Nirmal314/omarchy-van-gogh-theme"
)
for url in "${THEMES[@]}"; do
    omarchy-theme-install "$url" 2>/dev/null || echo "  (already installed or failed: $url)"
done

# --- Claude Code --------------------------------------------------------------
echo ""
echo "Setting up Claude Code..."
"$SCRIPT_DIR/install-claude.sh"
"$SCRIPT_DIR/link-claude.sh"

# --- Services -----------------------------------------------------------------
echo ""
echo "Enabling services..."
sudo systemctl enable --now docker 2>/dev/null || true
sudo usermod -aG docker "$USER" 2>/dev/null || true

# --- Restart affected components ----------------------------------------------
echo ""
echo "Restarting components..."
omarchy-restart-waybar 2>/dev/null || true
omarchy-restart-walker 2>/dev/null || true

echo ""
echo "=== Done ==="
echo ""
echo "Manual steps:"
echo "  1. hyprctl reload (or log out/in for full effect)"
echo "  2. Set theme: omarchy-theme-set 'Tokyo Night'"
echo "  3. Log out and back in for docker group membership"
echo "  4. Open WezTerm: it should pick up BiDi + omarchy theme colors"
