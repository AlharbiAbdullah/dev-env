# dev-env

Personal dev environment for the Omarchy hub and the Mac, mirrored 1:1.

## Layout

| Path | Contents |
|---|---|
| `mac/` | zsh, Ghostty, tmux, AeroSpace, starship, theme system, Brewfile, `setup.sh` |
| `linux/omarchy/` | Omarchy 4 layer: personal deltas over Omarchy defaults, `install.sh` + backup/restore (see its README) |
| `archive/theming/` | the retired custom theme system (2026-10-04); the hub runs stock Omarchy |

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

## Themes

The hub runs stock Omarchy themes and wallpapers (`SUPER CTRL T` theme menu,
`SUPER CTRL W` background menu). The custom theme system was retired 2026-10-04
and lives in `archive/theming/`. The Mac keeps its `theme` script until it is sold.

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
| `SUPER CTRL T` / `SUPER CTRL W` | Theme menu / background menu |
| `Alt+Shift` | Toggle keyboard layout `us` ↔ `ara` |

## Sync model

Copy-based, not symlinked. After changing a live config, copy it back into the
repo manually.
