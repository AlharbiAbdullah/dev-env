#!/usr/bin/env bash
# install-claude.sh — installs Claude Code via the official native installer.
# This is the recommended install method per docs.claude.com.
# npm installation is deprecated.

set -e

echo "=== Installing Claude Code (native installer) ==="
curl -fsSL https://claude.ai/install.sh | bash

echo ""
echo "Adding ~/.local/bin to PATH if needed..."

SHELL_RC=""
if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

if ! grep -q '.local/bin' "$SHELL_RC" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    echo "  -> appended PATH export to $SHELL_RC"
fi

echo ""
echo "=== Done ==="
echo "1. Restart your shell or run: source $SHELL_RC"
echo "2. Verify: claude --version"
echo "3. Health check: claude doctor"
echo "4. First run: claude (will open browser for login)"
