#!/bin/bash
# Fix fonts for WezTerm on Linux
# Uses JetBrains Mono (available in Ubuntu repos)

sudo apt install -y fonts-jetbrains-mono fonts-cairo
fc-cache -fv

# Update WezTerm config to use JetBrains Mono
sed -i 's/NotoSansM Nerd Font/JetBrains Mono/g' ~/.wezterm.lua
sed -i 's/Apple Color Emoji/Noto Color Emoji/g' ~/.wezterm.lua

echo ""
echo "Done. Close and reopen WezTerm."
