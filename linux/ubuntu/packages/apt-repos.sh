#!/usr/bin/env bash
# apt-repos.sh — third-party apt repositories + signing keys.
# Idempotent. Run BEFORE installing packages/apt.txt: wezterm and
# google-chrome-stable live in these repos, not in the Ubuntu archive.
set -euo pipefail

HYPRLAND_PPA=0
for arg in "$@"; do
    case "$arg" in
        --hyprland-ppa) HYPRLAND_PPA=1 ;;
    esac
done

echo "  universe repository..."
sudo add-apt-repository -y universe

if [ "$HYPRLAND_PPA" -eq 1 ]; then
    echo "  ppa:cppiber/hyprland (newer Hyprland)..."
    sudo add-apt-repository -y ppa:cppiber/hyprland
fi

# --- WezTerm (apt.fury.io) ---
if [ ! -f /etc/apt/keyrings/wezterm-fury.gpg ]; then
    echo "  WezTerm fury repo..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
        | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
fi

# --- Google Chrome (dl.google.com; deb822 .sources to match the vendor default) ---
if [ ! -f /usr/share/keyrings/google-chrome.gpg ]; then
    echo "  Google Chrome repo..."
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | sudo gpg --yes --dearmor -o /usr/share/keyrings/google-chrome.gpg
    sudo tee /etc/apt/sources.list.d/google-chrome.sources >/dev/null <<'EOF'
X-Repolib-Name: Google Chrome
Types: deb
URIs: https://dl.google.com/linux/chrome/deb/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/google-chrome.gpg
EOF
fi

echo "  apt-get update..."
sudo apt-get update
