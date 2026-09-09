# dev-env

Personal dev environment for the Omarchy hub and the Mac, mirrored 1:1.

## Layout

| Path | Contents |
|---|---|
| `mac/` | zsh, Ghostty, tmux, AeroSpace, starship, theme system, Brewfile, `setup.sh` |
| `linux/omarchy/` | Omarchy 4 layer: personal deltas over Omarchy defaults, `install.sh` + backup/restore (see its README) |
| `common/themes/` | 14 shared theme definitions (`theme.lua`) + 4 dharmx wallpapers each, consumed by mac and omarchy |
| `common/wallpaper/` | General wallpaper collection |

## Usage

```bash
git clone https://github.com/AlharbiAbdullah/dev-env.git
```

**macOS:**

```bash
cd mac && ./setup.sh
```

**Omarchy hub:**

```bash
cd linux/omarchy && ./install.sh   # see linux/omarchy/README.md
```

## Shells

Mac = **zsh**. Linux = **bash**. The rc files mirror the same tools and aliases
(starship, zoxide, fzf, eza, git shortcuts) — only the shell differs.

## Secrets

API keys live in a gitignored machine-local file the rc file sources on startup:
`~/.zshrc.local` on Mac, `~/.bashrc.local` on the hub.

```bash
# Mac
cp mac/.zshrc.local.example ~/.zshrc.local
# Omarchy hub
cp mac/.zshrc.local.example ~/.bashrc.local   # secrets resolve from 1Password via op (see the __op_env helper)
```

## Theme system

Same commands on both platforms:

| Command | Action |
|---|---|
| `theme` | Show the current theme |
| `theme <name>` | Switch to a named theme |
| `theme cycle` | Switch to the next theme |
| `theme pick` | Fuzzy-pick a theme |
| `theme wallpaper next` | Switch to the next wallpaper for the current theme |

Keybindings:

| Action | Hub | Mac |
|---|---|---|
| Cycle theme | `SUPER CTRL T` | `CMD CTRL T` |
| Next wallpaper | `SUPER CTRL W` | `CMD CTRL W` |

## Hub parity checklist

After install, smoke-test the key bindings on the hub:

| Binding | Expected |
|---|---|
| `SUPER 1..0` | Switch to workspace 1..10 |
| `SUPER ←↑↓→` | Move focus |
| `SUPER RETURN` | New Ghostty window |
| `SUPER SPACE` | App launcher (Omarchy menu) |
| `SUPER W` | Close active window |
| `SUPER F` | Toggle fullscreen |
| `ALT S` | Region screenshot to clipboard |
| `Print` | Full screenshot to `~/Pictures` |
| `SUPER CTRL T` / `SUPER CTRL W` | Cycle theme / next wallpaper |
| `Alt+Shift` | Toggle keyboard layout `us` ↔ `ara` |

Theme test one-liners:

```bash
theme gruvbox
hyprctl getoption general:col.active_border   # border recolored
grep '^palette' ~/.config/starship.toml       # starship palette switched
```

## Sync model

Copy-based, not symlinked. After changing a live config, copy it back into the
repo manually.
