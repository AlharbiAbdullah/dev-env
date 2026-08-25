# linux/omarchy — Omarchy 4 layer

Reproduces the Ubuntu box (as back-synced into `linux/ubuntu/` on 2026-08-25) on a fresh
Omarchy 4.0.1 install. Omarchy owns the desktop (Quickshell bar/menu/notifications/lock,
wallpaper, Hyprland defaults, theme generation); this layer adds the personal deltas.

| Path | What |
|---|---|
| `install.sh` | one-shot bootstrap, idempotent; `ENABLE_TIMERS=0` for cutover staging |
| `backup-ubuntu.sh` | run ON THE UBUNTU BOX before the wipe; backs up to `mac:~/backups/linux-<date>/` |
| `restore-backup.sh` | run on the new box after `install.sh`; `--heavy` adds docker volumes + ollama models |
| `packages/{pacman,aur}.txt` | packages beyond Omarchy's base |
| `config/hypr/*.lua` | Hyprland overrides (Lua, Omarchy 4 convention): monitor 1440p@100 scale 1, `us,ara` Alt+Shift, gaps/border/blur, personal binds, xremap autostart |
| `config/omarchy/shell.json` | bar layout + clock format + idle 600/900 |
| `config/omarchy/hooks/theme-set.d/rai-theme-set` | after every theme switch: tmux bar, starship palette, `~/.config/themes/current.lua` pointer |
| `theme`, `theme-render` | switcher wrapper over `omarchy theme`; renderer `theme.lua` -> `~/.config/omarchy/themes/<n>/{colors.toml,vscode.json,backgrounds/}` |
| `config/{ghostty,xremap,micro,glow,git,fastfetch,opencode}`, `mimeapps.list`, `starship.toml`, `.tmux.conf`, `.bashrc` | carried configs |
| `systemd/` | the 5 timers + xremap.service (xvfb dropped: nothing scheduled uses it) |
| `etc/` | sudoers NOPASSWD, xremap udev, 1Password polkit, ollama expose |
| `claude/`, `claude-config.sh` | Claude Code local files + the 8 vault symlinks + pi/opencode edges |

What Omarchy replaces from the Ubuntu layer: waybar, rofi, mako (muted: use `Super+Ctrl+,` silencing toggle), hypridle/hyprlock, swaybg, hyprpolkitagent, grim/slurp binds (kept as Ctrl+3/4 to clipboard), the theme script's Ghostty/Chrome/gsettings/VS Code/Cursor/wallpaper writers.

Fresh box:

```bash
gh auth login && git clone https://github.com/AlharbiAbdullah/dev-env.git ~/dev-env
cd ~/dev-env/linux/omarchy && ENABLE_TIMERS=0 ./install.sh && ./restore-backup.sh --heavy
```

Then the manual logins `install.sh` prints, and the checklist in
`~/helm/05-projects/kitchen/omarchy-migration/checklist.md`.
