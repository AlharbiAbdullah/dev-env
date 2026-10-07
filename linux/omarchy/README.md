# linux/omarchy — Omarchy 4 layer

Personal layer on a fresh Omarchy 4 install. Omarchy owns the desktop (Quickshell bar/menu/notifications/lock,
wallpaper, Hyprland defaults, themes); this layer adds the personal deltas. Themes and wallpapers are stock
Omarchy: the custom theme system was retired 2026-10-04 (`archive/theming/`).

| Path | What |
|---|---|
| `install.sh` | one-shot bootstrap, idempotent; `ENABLE_TIMERS=0` for cutover staging |
| `backup-ubuntu.sh` | run ON THE UBUNTU BOX before the wipe; backs up to `mac:~/backups/linux-<date>/` |
| `restore-backup.sh` | run on the new box after `install.sh`; `--heavy` adds docker volumes + ollama models |
| `packages/{pacman,aur}.txt` | packages beyond Omarchy's base |
| `config/hypr/*.lua` | Hyprland overrides (Lua, Omarchy 4 convention): monitor 1440p@100 scale 1, `us,ara` Alt+Shift, gaps/border/blur, personal binds, xremap autostart |
| `config/omarchy/shell.json` | bar layout + clock format + idle 600/900 |
| `agents-local` | writes the `pi`, `opencode` and `agy` usage records the Omarchy agents bar panel reads; the stock collectors only cover `claude`, `codex` and `fireworks`. Driven by the `agents-local` timer |
| `agents-panel-setup.sh`, `agents-panel/` | clones the Omarchy agents panel (`abdullah.agents`) so it can carry `pi`/`opencode`/`agy`/`AI` marks and give the `AI` record a model-only layout; `Main.qml`/`Agent.qml` stay symlinked to the package, `Panel.qml` is a patched copy re-applied on every run and after `omarchy update` |
| `config/{ghostty,xremap,micro,glow,git,fastfetch,opencode}`, `mimeapps.list`, `starship.toml`, `.tmux.conf`, `.bashrc` | carried configs |
| `systemd/` | the 5 timers + xremap.service (xvfb dropped: nothing scheduled uses it) |
| `etc/` | sudoers NOPASSWD, xremap udev, 1Password polkit, ollama expose |
| `claude/`, `claude-config.sh` | Claude Code local files + the 5 vault symlinks + Context7 at user scope + pi/opencode edges |

What Omarchy replaces from the Ubuntu layer: waybar, rofi, mako (muted: use `Super+Ctrl+,` silencing toggle), hypridle/hyprlock, swaybg, hyprpolkitagent, grim/slurp binds (kept as Ctrl+3/4 to clipboard), all theming.

Fresh box:

```bash
gh auth login && git clone https://github.com/AlharbiAbdullah/dev-env.git ~/dev-env
cd ~/dev-env/linux/omarchy && ENABLE_TIMERS=0 ./install.sh && ./restore-backup.sh --heavy
```

Then the manual logins `install.sh` prints, and the checklist in
`~/helm/05-projects/completed/omarchy-migration/checklist.md`.
