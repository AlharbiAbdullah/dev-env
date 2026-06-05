#!/usr/bin/env bash
# Ubuntu 26.04 (Hyprland) setup. 1:1 port of the live macOS terminal/wm setup.
# Idempotent: safe to re-run. Copies configs (no symlinks); user syncs manually.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Repo layout: linux/ubuntu/setup.sh -> REPO_ROOT is two levels up.
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- Guard: Linux + apt only ---
if [ "$(uname -s)" = "Darwin" ]; then
    echo "This script is for Linux only. Use mac/setup.sh on macOS."
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "apt-get not found. This script targets Ubuntu/Debian (26.04 LTS)."
    exit 1
fi

# --- Flags ---
HYPRLAND_PPA=0
for arg in "$@"; do
    case "$arg" in
        --hyprland-ppa) HYPRLAND_PPA=1 ;;
        -h|--help)
            echo "Usage: $0 [--hyprland-ppa]"
            echo "  --hyprland-ppa  Install newer Hyprland via ppa:cppiber/hyprland"
            echo "                  (default: Hyprland from the universe repo)"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg (try --help)"
            exit 1
            ;;
    esac
done

echo "=== Ubuntu 26.04 Hyprland Setup ==="

# --- Enable universe + refresh ---
echo "Enabling universe repository..."
sudo add-apt-repository -y universe
sudo apt-get update

# --- Optional newer Hyprland PPA ---
if [ "$HYPRLAND_PPA" -eq 1 ]; then
    echo "Adding ppa:cppiber/hyprland for newer Hyprland..."
    sudo add-apt-repository -y ppa:cppiber/hyprland
    sudo apt-get update
fi

# --- WezTerm apt repo (not in Ubuntu repos) ---
if [ ! -f /etc/apt/keyrings/wezterm-fury.gpg ]; then
    echo "Adding WezTerm apt repository..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
    sudo apt-get update
fi

# --- Packages ---
echo "Installing packages..."
sudo apt-get install -y \
    hyprland waybar fuzzel swaybg mako-notifier hyprlock hypridle \
    hyprpolkitagent xdg-desktop-portal-hyprland \
    wl-clipboard grim slurp \
    eza zoxide fzf bat btop fastfetch gh starship lazygit jq \
    zsh git curl unzip fontconfig \
    zsh-syntax-highlighting zsh-autosuggestions \
    fonts-cairo fonts-noto fonts-noto-color-emoji \
    wezterm tmux \
    build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev libffi-dev liblzma-dev

# --- Nerd Font (matches WezTerm font family: NotoSansM Nerd Font) ---
if ! fc-list | grep -qi "NotoSansM Nerd Font"; then
    echo "Installing NotoSansM Nerd Font..."
    font_tmp="$(mktemp -d)"
    curl -fsSL -o "$font_tmp/Noto.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Noto.zip
    unzip -o -q "$font_tmp/Noto.zip" -d "$font_tmp/Noto"
    mkdir -p "$HOME/.local/share/fonts"
    find "$font_tmp/Noto" -name 'NotoSansMNerdFont*.ttf' -exec cp {} "$HOME/.local/share/fonts/" \;
    rm -rf "$font_tmp"
    fc-cache -f
fi

# --- pyenv ---
if ! command -v pyenv >/dev/null 2>&1 && [ ! -d "$HOME/.pyenv" ]; then
    echo "Installing pyenv..."
    curl -fsSL https://pyenv.run | bash
fi

# --- nvm ---
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing nvm..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# --- TPM (tmux plugin manager) ---
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing TPM (tmux plugin manager)..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# --- Target directories ---
mkdir -p \
    "$HOME/.config/hypr" \
    "$HOME/.config/waybar" \
    "$HOME/.local/bin" \
    "$HOME/.cache/theme" \
    "$HOME/Pictures"

# --- Copy configs (copy model, not symlinks) ---
echo ""
echo "Copying configs..."

cp "$SCRIPT_DIR/.zshrc"        "$HOME/.zshrc";                       echo "  -> ~/.zshrc"
cp "$SCRIPT_DIR/.wezterm.lua"  "$HOME/.wezterm.lua";                 echo "  -> ~/.wezterm.lua"
cp "$SCRIPT_DIR/.tmux.conf"    "$HOME/.tmux.conf";                   echo "  -> ~/.tmux.conf"
cp "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml";        echo "  -> ~/.config/starship.toml"

cp "$SCRIPT_DIR/hyprland.conf" "$HOME/.config/hypr/hyprland.conf";   echo "  -> ~/.config/hypr/hyprland.conf"
cp "$SCRIPT_DIR/hypridle.conf" "$HOME/.config/hypr/hypridle.conf";   echo "  -> ~/.config/hypr/hypridle.conf"
cp "$SCRIPT_DIR/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf";   echo "  -> ~/.config/hypr/hyprlock.conf"

cp -R "$SCRIPT_DIR/waybar/." "$HOME/.config/waybar/";                echo "  -> ~/.config/waybar/"

cp "$SCRIPT_DIR/theme"      "$HOME/.local/bin/theme"
cp "$SCRIPT_DIR/new-window" "$HOME/.local/bin/new-window"
chmod +x "$HOME/.local/bin/theme" "$HOME/.local/bin/new-window"
echo "  -> ~/.local/bin/{theme,new-window} (chmod +x)"

# --- Themes (shared data) ---
if [ ! -d "$HOME/.config/themes" ]; then
    echo "Copying theme collection..."
    cp -R "$REPO_ROOT/common/themes" "$HOME/.config/themes"
fi
if [ ! -e "$HOME/.config/themes/current.lua" ]; then
    ln -sfn "$HOME/.config/themes/everforest/theme.lua" "$HOME/.config/themes/current.lua"
    echo "  -> default theme: everforest"
fi

# --- Default shell ---
ZSH_BIN="$(command -v zsh)"
if [ "${SHELL:-}" != "$ZSH_BIN" ]; then
    echo "Setting zsh as default shell..."
    chsh -s "$ZSH_BIN" || echo "  chsh failed; run manually: chsh -s $ZSH_BIN"
fi

# --- Done ---
cat <<EOF

=== Done ===
1. Log out, then pick "Hyprland" from the session menu in GDM and log back in.
2. Create ~/.zshrc.local with your secret(s):
     echo 'export OPENROUTER_API_KEY="sk-or-..."' > ~/.zshrc.local
3. Install Claude Code:
     "$SCRIPT_DIR/install-claude.sh"
4. In WezTerm, run tmux, then press prefix + I to install tmux plugins.

Theme / wallpaper keybindings (inside Hyprland):
  SUPER CTRL T   cycle theme
  SUPER CTRL W   next wallpaper
EOF
