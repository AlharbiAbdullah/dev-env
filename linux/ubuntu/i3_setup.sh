#!/bin/bash
# i3 window manager setup for Ubuntu/Debian
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$(uname -s)" = "Darwin" ]; then
    echo "i3 is Linux only. Use Aerospace on macOS."
    exit 0
fi

echo "=== i3 Window Manager Setup ==="

# --- Install i3 and tools ---
echo "Installing i3 and utilities..."
sudo apt update
sudo apt install -y \
    i3 \
    i3status \
    i3lock \
    rofi \
    feh \
    picom \
    dunst \
    network-manager-gnome \
    xclip

# --- Create config directories ---
mkdir -p "$HOME/.config/i3"
mkdir -p "$HOME/.config/i3status"

# --- Copy configs ---
echo "Copying config files..."

cp "$SCRIPT_DIR/i3_config" "$HOME/.config/i3/config"
echo "  -> ~/.config/i3/config"

cp "$SCRIPT_DIR/i3status.conf" "$HOME/.config/i3status/config"
echo "  -> ~/.config/i3status/config"

echo ""
echo "=== Done ==="
echo "Log out and select 'i3' from the session menu at login."
