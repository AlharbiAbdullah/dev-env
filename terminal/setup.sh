#!/bin/bash
# Terminal setup script
# Works on both macOS and Ubuntu/Debian

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

echo "=== Terminal Setup ==="
echo "OS: $OS"
echo ""

# --- Zsh ---
if ! command -v zsh >/dev/null 2>&1; then
    echo "Installing zsh..."
    if [ "$OS" = "Darwin" ]; then
        brew install zsh
    else
        sudo apt update && sudo apt install -y zsh
    fi
fi

# --- Oh My Zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- Zsh plugins ---
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# --- WezTerm ---
if ! command -v wezterm >/dev/null 2>&1; then
    echo "Installing WezTerm..."
    if [ "$OS" = "Darwin" ]; then
        brew install --cask wezterm
    else
        curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
        echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
        sudo apt update && sudo apt install -y wezterm
    fi
fi

# --- Tmux ---
if ! command -v tmux >/dev/null 2>&1; then
    echo "Installing tmux..."
    if [ "$OS" = "Darwin" ]; then
        brew install tmux
    else
        sudo apt install -y tmux
    fi
fi

# --- TPM (Tmux Plugin Manager) ---
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# --- Fonts ---
echo "Installing NotoSansM Nerd Font and Cairo..."
if [ "$OS" = "Darwin" ]; then
    brew install --cask font-noto-sans-mono-nerd-font
    brew install --cask font-cairo
else
    mkdir -p "$HOME/.local/share/fonts"
    # Noto Sans Mono Nerd Font
    if ! fc-list | grep -qi "NotoSansM Nerd"; then
        curl -fsSL -o /tmp/NotoSansMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NotoSansMono.zip"
        unzip -o /tmp/NotoSansMono.zip -d "$HOME/.local/share/fonts/NotoSansMono/"
        rm /tmp/NotoSansMono.zip
    fi
    # Cairo font
    if ! fc-list | grep -qi "Cairo"; then
        sudo apt install -y fonts-cairo || {
            curl -fsSL -o /tmp/Cairo.zip "https://fonts.google.com/download?family=Cairo"
            unzip -o /tmp/Cairo.zip -d "$HOME/.local/share/fonts/Cairo/"
            rm /tmp/Cairo.zip
        }
    fi
    fc-cache -fv
fi

# --- Copy config files ---
echo ""
echo "Copying config files..."

cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
echo "  -> ~/.zshrc"

cp "$SCRIPT_DIR/.wezterm.lua" "$HOME/.wezterm.lua"
echo "  -> ~/.wezterm.lua"

cp "$SCRIPT_DIR/.tmux.conf" "$HOME/.tmux.conf"
echo "  -> ~/.tmux.conf"

# Only copy .zprofile on macOS (has brew shellenv)
if [ "$OS" = "Darwin" ]; then
    cp "$SCRIPT_DIR/.zprofile" "$HOME/.zprofile"
    echo "  -> ~/.zprofile"
fi

# --- Set default shell to zsh ---
if [ "$SHELL" != "$(which zsh)" ]; then
    echo ""
    echo "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

echo ""
echo "=== Done ==="
echo "Restart your terminal or run: exec zsh"
