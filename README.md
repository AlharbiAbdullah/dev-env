# dev-env

Personal dev environment for macOS + Ubuntu, mirrored 1:1.

## Layout

| Path | Contents |
|---|---|
| `mac/` | zsh, WezTerm, tmux, AeroSpace, starship, ghostty, theme system, Brewfile, `setup.sh` |
| `linux/ubuntu/` | Hyprland mirror of the Mac setup for Ubuntu 26.04 LTS (bash shell), `setup.sh` |
| `linux/Omarchy/` | Arch + Hyprland reference, kept as-is |
| `common/themes/` | 17 shared theme definitions + per-theme wallpapers, consumed by both platforms |
| `common/wallpaper/` | General wallpaper collection |

## Usage

```bash
git clone https://github.com/AlharbiAbdullah/dev-env.git
```

**macOS:**

```bash
cd mac && ./setup.sh
```

**Ubuntu — full one-shot rebuild (fresh machine):**

```bash
cd linux/ubuntu && ./bootstrap.sh   # pass --hyprland-ppa for the newer Hyprland PPA
```

`bootstrap.sh` is idempotent and does everything: NOPASSWD sudoers, clones `~/helm`
and `~/work/mirsad`, installs packages (`packages/apt.txt` + snaps + Obsidian), copies
dotfiles (via `setup.sh`), sets up Claude Code, and installs + enables the scheduled
jobs (`systemd/`). For the machine-to-machine cutover (the single-writer ChromaDB
handoff), follow **[linux/ubuntu/MIGRATION.md](linux/ubuntu/MIGRATION.md)** and stage
with `ENABLE_TIMERS=0 ./bootstrap.sh` so the timers don't arm early.

**Ubuntu — dotfiles only (already-set-up machine):**

```bash
cd linux/ubuntu && ./setup.sh   # configs/fonts/tools only, no system changes
```

Then log out and pick **Hyprland** in the GDM session menu.

## Shells

Mac = **zsh**. Linux = **bash**. The rc files mirror the same tools and aliases
(starship, zoxide, fzf, eza, git shortcuts) — only the shell differs.

## Secrets

API keys live in a gitignored machine-local file the rc file sources on startup:
`~/.zshrc.local` on Mac, `~/.bashrc.local` on Ubuntu.

```bash
# Mac
cp mac/.zshrc.local.example ~/.zshrc.local
# Ubuntu
echo 'export OPENROUTER_API_KEY="sk-or-..."' > ~/.bashrc.local
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
