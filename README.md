# Dev_Env

Personal dev environment for macOS + Ubuntu, mirrored 1:1.

## Layout

| Path | Contents |
|---|---|
| `mac/` | zsh, WezTerm, tmux, AeroSpace, starship, ghostty, theme system, Brewfile, `setup.sh` |
| `linux/ubuntu/` | Hyprland mirror of the Mac setup for Ubuntu 26.04 LTS, `setup.sh` |
| `linux/Omarchy/` | Arch + Hyprland reference, kept as-is |
| `common/themes/` | 17 shared theme definitions + per-theme wallpapers, consumed by both platforms |
| `common/wallpaper/` | General wallpaper collection |

## Usage

```bash
git clone https://github.com/AlharbiAbdullah/Dev_Env.git
```

**macOS:**

```bash
cd mac && ./setup.sh
```

**Ubuntu:**

```bash
cd linux/ubuntu && ./setup.sh   # pass --hyprland-ppa for the newer Hyprland PPA
```

Then log out and pick **Hyprland** in the GDM session menu.

## Secrets

API keys live in `~/.zshrc.local`, which is gitignored. `.zshrc` sources it on
startup. Copy the template and fill in real values:

```bash
cp mac/.zshrc.local.example ~/.zshrc.local
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

| Action | Ubuntu | Mac |
|---|---|---|
| Cycle theme | `SUPER CTRL T` | `CMD CTRL T` |
| Next wallpaper | `SUPER CTRL W` | `CMD CTRL W` |

## Ubuntu parity checklist

After install, smoke-test the key bindings on the Ubuntu box:

| Binding | Expected |
|---|---|
| `SUPER 1..0` | Switch to workspace 1..10 |
| `SUPER ←↑↓→` | Move focus |
| `SUPER RETURN` | New WezTerm window |
| `SUPER D` | App launcher (fuzzel) |
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
