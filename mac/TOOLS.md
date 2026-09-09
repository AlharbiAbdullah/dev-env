# Mac Tools

Inventory of tools on the Mac. The Mac mirrors the Omarchy hub 1:1 (every add or remove on one machine is mirrored on the other); the declared list is `Brewfile`, editor extensions are `../common/editor-extensions.txt`, uv tools are `../common/uv-tools.txt`.

## Terminal & Shell
- Ghostty (primary); iTerm2 for Arabic (Ghostty is still LTR-only)
- zsh
- starship (prompt)
- zoxide (smart cd)
- fzf (fuzzy finder)
- eza (ls replacement)
- bat (cat replacement)
- btop (process monitor)
- fastfetch (system info)
- tmux + TPM + tmux-resurrect + tmux-continuum (shared `tmux.conf`)
- micro (terminal editor)

## Window Management
- AeroSpace (tiling WM)
- JankyBorders (`borders`, active-window borders)
- Hammerspoon (Lua automation)
- LinearMouse (pointer and scroll)
- Bartender (menu bar manager)
- Stats (menu bar system monitor)

## Theme System
- `theme` / `menu-toggle` / `new-window` scripts (`mac/bin/`)
- `~/.config/themes/`: shared theme definitions from `common/themes/`

## Editors & IDEs
- VS Code (`code .`) and Cursor (`cur .`), same extensions and settings

## AI / Coding Agents
- Claude Code (via mise)
- OpenCode (via mise)
- pi (via mise, OpenRouter)

## Languages & Runtimes
- Python (uv; ruff, ty)
- Node.js (mise)

## Package Managers
- Homebrew + Brewfile
- mise (`~/.config/mise/config.toml`)

## Version Control
- Git
- gh (GitHub CLI, via mise)
- lazygit

## Apps
- Raycast (launcher)
- Shottr (screenshots)
- OrbStack (containers/VMs)
- Tailscale (mesh VPN)
- Syncthing (six folders with the hub)
- 1Password CLI (`op`, every secret; shells read via `__op_env`)
- gcloud CLI

## Fonts
- NotoSansM Nerd Font
- Cairo

> `mas`-installed App Store apps and npm global packages are captured in the
> `Brewfile` too (`mas` and `npm` entries).
