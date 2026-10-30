# dev-env

Personal dev environment for the Omarchy hub and replica.

## Layout

| Path | Contents |
|---|---|
| `linux/omarchy/` | Omarchy 4 layer: personal deltas over Omarchy defaults, `install.sh` + backup/restore (see its README) |
| `archive/theming/` | the retired custom theme system (2026-10-04); the hub runs stock Omarchy |

## Usage

```bash
git clone https://github.com/AlharbiAbdullah/dev-env.git
```

**Omarchy hub:**

```bash
cd linux/omarchy && RAI_ROLE=producer ./install.sh   # see linux/omarchy/README.md
```

## Shells

Both machines use **bash** with starship, zoxide, fzf, eza and git shortcuts.

## Secrets

Secrets live in 1Password and load through `__op_env`. The shell sources the
machine-local `~/.bashrc.local` file. Its tracked example contains only 1Password references.

```bash
cp linux/omarchy/.bashrc.local.example ~/.bashrc.local
```

## Themes

The hub runs stock Omarchy themes and wallpapers (`SUPER CTRL T` theme menu,
`SUPER CTRL W` background menu). The custom theme system was retired 2026-10-04
and lives in `archive/theming/`.

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
