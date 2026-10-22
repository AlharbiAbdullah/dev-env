# linux/omarchy: Omarchy 4 layer

Personal layer on a fresh Omarchy 4 install. Omarchy owns the desktop (Quickshell bar/menu/notifications/lock,
wallpaper, Hyprland defaults, themes); this layer adds the personal deltas. Themes and wallpapers are stock
Omarchy: the custom theme system was retired 2026-10-04 (`archive/theming/`).

| Path | What |
|---|---|
| `install.sh` | one-shot bootstrap, idempotent; `ENABLE_TIMERS=0` for cutover staging |
| `backup-ubuntu.sh` | run ON THE UBUNTU BOX before the wipe; backs up to `mac:~/backups/linux-<date>/` |
| `backup-drive` | weekly encrypted home and machine-state snapshots in the existing restic repository |
| `restore-backup.sh` | verify and stage both snapshot types in a new private folder, without the Mac |
| `restic-excludes.txt` | portable exclusion rules, installed as `~/.config/restic/excludes.txt` |
| `packages/{pacman,aur}.txt` | packages beyond Omarchy's base |
| `config/hypr/*.lua` | Hyprland overrides (Lua, Omarchy 4 convention): monitor 1440p@100 scale 1, `us,ara` Alt+Shift, gaps/border/blur, personal binds, xremap autostart |
| `config/omarchy/shell.json` | bar layout + clock format + idle 600/900 |
| `agents-local` | writes the `pi`, `opencode` and `agy` usage records the Omarchy agents bar panel reads; the stock collectors only cover `claude`, `codex` and `fireworks`. Driven by the `agents-local` timer |
| `agents-panel-setup.sh`, `agents-panel/` | clones the Omarchy agents panel (`abdullah.agents`) to carry `pi`/`opencode`/`agy`/`AI` marks. The `AI` record gets a model-only layout. `Main.qml`/`Agent.qml` stay symlinked to the package. The patched `Panel.qml` copy is re-applied on every run and after `omarchy update` |
| `config/{ghostty,xremap,micro,glow,git,fastfetch,opencode}`, `mimeapps.list`, `starship.toml`, `.tmux.conf`, `.bashrc` | carried configs |
| `systemd/` | the 5 timers + xremap.service (xvfb dropped: nothing scheduled uses it) |
| `etc/` | sudoers NOPASSWD, xremap udev, 1Password polkit, ollama expose |
| `claude/`, `claude-config.sh` | Claude Code local files + the 5 vault symlinks + Context7 at user scope + pi/opencode edges |

Omarchy replaces the Ubuntu layer's waybar, rofi, mako, hypridle/hyprlock, swaybg, hyprpolkitagent and theming.
Use `Super+Ctrl+,` to mute notifications. The grim/slurp binds stay Ctrl+3/4 to the clipboard.

Fresh box:

```bash
gh auth login && git clone https://github.com/AlharbiAbdullah/dev-env.git ~/dev-env
cd ~/dev-env/linux/omarchy && ENABLE_TIMERS=0 ./install.sh
```

Recover the backup credentials, stage the restore below, and review it before applying files.
Then follow the manual logins that `install.sh` prints and the checklist in
`~/helm/05-projects/completed/omarchy-migration/checklist.md`.

## Recover from the encrypted backup

1. Install restic and rclone. Both are declared in `packages/pacman.txt`.
2. Recover the password, OAuth client and rclone configuration from the 1Password item
   "restic backup Google Drive". Restore the local credential files without printing them.
   The repository is `rclone:gdrive:Backup/restic`; retain the original OAuth client configuration.
3. Stage the recovery in a new absolute target directory:

   ```bash
   ./restore-backup.sh --target "$HOME/restore-review"
   ```

The target must not already exist. It is created with mode `0700`. `target/home/` holds the home
snapshot's original path tree. `target/archive/machine-state.tar` holds the machine archive, and
`target/system/` holds its extracted `/etc` and `/var/lib/tailscale` trees. Restic verifies restored
contents. The command never writes over live files, runs sudo, or connects to the Mac.

The default selects the newest `home-state` and `machine-state` snapshots independently.
To select specific snapshots:

```bash
./restore-backup.sh --target "$HOME/restore-review-selected" \
  --home-snapshot <home-snapshot-id> --machine-snapshot <machine-snapshot-id>
```

An older home snapshot can be selected by ID, but it cannot supply files omitted by the old
backup. A machine-state snapshot is required for the system archive. Before relying on recovery,
confirm both snapshot types exist and complete a restore drill in a separate folder.

Review the staged files before copying anything onto a rebuilt machine. Applying root-owned
files is a separate recovery step that preserves their original ownership and modes. Stop
Tailscale before restoring the same machine's identity. New hardware gets its own identity.
Browser and application sign-ins are completed on the new machine.

`backup-drive` adds `~/.ssh` and `~/.config` to its `home-state` snapshot. A second snapshot streams
`/etc` and `/var/lib/tailscale` directly from the existing noninteractive sudo command into restic.
No plaintext machine archive is left on the source machine. Both snapshots must succeed and be
fresh before retention runs. Backup waits for maintenance's shared lock and holds it through
the whole job. `install.sh` copies the exclusion list without changing local credentials.
