#!/usr/bin/env bash
# dev-env macOS setup. Copies dotfiles/configs/scripts from the repo into $HOME.
# Deploy model: COPY (not symlink) — re-run after `git pull` to sync. Idempotent.
set -euo pipefail

# --- Darwin guard ---
if [ "$(uname -s)" != "Darwin" ]; then
    echo "This script is for macOS only. Use linux/ubuntu/setup.sh on Linux."
    exit 1
fi

echo "=== dev-env macOS Setup ==="

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Load brew into this shell's environment (Apple Silicon vs Intel prefix).
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
else
    echo "Homebrew install appears to have failed: no brew binary found." >&2
    exit 1
fi

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Brew bundle ---
echo ""
echo "Installing packages from Brewfile..."
brew bundle --file="$SCRIPT_DIR/Brewfile"

# --- Directories ---
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.cache/theme"
mkdir -p "$HOME/.config/ghostty"

# --- Copy dotfiles and configs ---
echo ""
echo "Copying config files..."

cp "$SCRIPT_DIR/.zshrc"           "$HOME/.zshrc";                    echo "  -> ~/.zshrc"
cp "$SCRIPT_DIR/.zprofile"        "$HOME/.zprofile";                 echo "  -> ~/.zprofile"
cp "$SCRIPT_DIR/.tmux.conf"       "$HOME/.tmux.conf";                echo "  -> ~/.tmux.conf"
cp "$SCRIPT_DIR/.aerospace.toml"  "$HOME/.aerospace.toml";           echo "  -> ~/.aerospace.toml"
cp "$SCRIPT_DIR/starship.toml"    "$HOME/.config/starship.toml";     echo "  -> ~/.config/starship.toml"
cp "$SCRIPT_DIR/ghostty/config"   "$HOME/.config/ghostty/config";    echo "  -> ~/.config/ghostty/config"

# --- Copy bin scripts (make executable) ---
echo ""
echo "Installing scripts to ~/.local/bin..."
for script in theme menu-toggle new-window; do
    cp "$SCRIPT_DIR/bin/$script" "$HOME/.local/bin/$script"
    chmod +x "$HOME/.local/bin/$script"
    echo "  -> ~/.local/bin/$script"
done

# --- Themes (shared data under common/) ---
echo ""
if [ ! -d "$HOME/.config/themes" ]; then
    echo "Installing theme system to ~/.config/themes..."
    cp -R "$REPO_ROOT/common/themes" "$HOME/.config/themes"
    echo "  -> ~/.config/themes"
else
    echo "Note: ~/.config/themes already exists — left untouched (manual sync model)."
    echo "      To refresh, sync it from $REPO_ROOT/common/themes yourself."
fi

# Default active theme: everforest (only if nothing is selected yet).
if [ ! -e "$HOME/.config/themes/current.lua" ]; then
    ln -sfn "$HOME/.config/themes/everforest/theme.lua" "$HOME/.config/themes/current.lua"
    echo "  -> ~/.config/themes/current.lua (everforest)"
fi
if [ ! -e "$HOME/.config/ghostty/theme-current" ]; then
    ln -sfn "$HOME/.config/themes/everforest/ghostty.conf" "$HOME/.config/ghostty/theme-current"
    echo "  -> ~/.config/ghostty/theme-current (everforest)"
fi

# --- Secrets bootstrap ---
echo ""
if [ ! -f "$HOME/.zshrc.local" ]; then
    cp "$SCRIPT_DIR/.zshrc.local.example" "$HOME/.zshrc.local"
    echo "  -> ~/.zshrc.local (from example)"
    echo ""
    echo "  ************************************************************"
    echo "  *  ACTION REQUIRED: edit ~/.zshrc.local and fill in your   *"
    echo "  *  real secrets (e.g. OPENROUTER_API_KEY). It is NOT       *"
    echo "  *  tracked by git and the example value is a placeholder.  *"
    echo "  ************************************************************"
fi

# --- TPM (tmux plugin manager) ---
echo ""
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# --- VS Code (reference only, not auto-applied) ---
echo ""
echo "Note: mac/vscode/settings.json is a reference copy only. It is NOT"
echo "      auto-copied (that would clobber your live VS Code settings)."
echo "      Merge by hand if you want anything from it."

# --- Default shell ---
echo ""
if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
    echo "Your login shell is not zsh. To switch, run:"
    echo "    chsh -s \"\$(command -v zsh)\""
fi

# --- Done ---
echo ""
echo "=== Done ==="
echo "1. Restart your terminal (or run: exec zsh)."
echo "2. Run 'theme reload' to apply the active theme."
echo "3. In tmux, press prefix + I to install tmux plugins."
