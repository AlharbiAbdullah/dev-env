
# Omarchy migration guide

The short version. Every verify command lives in `checklist.md`; this is the order of operations.

## Before the wipe (on Ubuntu)

1. `~/dev-env/linux/omarchy/quiesce-ubuntu.sh` (disables the 5 timers, pushes helm + dev-env, final incremental backup to the Mac). Last command on Ubuntu.
2. `sudo reboot`, press F7, pick the SanDisk USB.
3. Installer answers, in the order it asks:
   - Keyboard: `English (US)`
   - Username: `abdullah`
   - Password: your choice (user + root)
   - Full name / email: `Abdullah Alharbi` / `alharbi.s.abdullah@gmail.com`
   - Hostname: `linux`
   - Timezone: `Asia/Riyadh`
   - Disk: the KINGSTON 1 TB NVMe (not the SanDisk)
   - Mode: `Full disk install`
   - Confirm screen: press **Ctrl+C** to flip to `Yes, install without encryption` (recommended: unattended timers, dirty shutdowns). Keeping LUKS is fine too; it means a passphrase at every boot.
   - "Everything will be overwritten": yes.

## After logging into Omarchy

Terminal is `Super+Return` (foot until step 3 installs Ghostty).

1. **Network**: click "Setup Wi-Fi" (or `Super+Ctrl+W`), join `Saad_5g`. Ethernet needs nothing. Click "Update System" (or `omarchy update`), reboot if asked.

2. **GitHub + dev-env**
   ```bash
   gh auth login
   git clone https://github.com/AlharbiAbdullah/dev-env.git ~/dev-env
   ```

3. **Install the layer** (10 to 20 min; AUR builds Chrome, Cursor, VS Code, ble.sh, xremap)
   ```bash
   cd ~/dev-env/linux/omarchy && ENABLE_TIMERS=0 ./install.sh
   ```
   Clones helm, installs packages, drops the Hyprland/Ghostty/theme configs, wires `~/.claude` to the vault, installs the timers without arming them.

4. **Pull the backup** from the Mac (Mac awake)
   ```bash
   ./restore-backup.sh
   ollama pull gpt-oss:20b && ollama pull bge-m3
   sudo reboot
   ```

5. **Logins** (no script can do these)
   - `tailscale up --ssh --hostname linux`
   - `claude` (browser login), then `claude plugin marketplace add jarrodwatts/claude-hud && claude plugin install claude-hud@claude-hud`
   - 1Password app: sign in, enable the SSH agent
   - Chrome: Google sign-in, then log in to x.com, substack.com, medium.com (news collectors read these cookies)
   - Obsidian: open `~/helm`, re-pair Sync, then with the app closed set `"cli": true` in `~/.config/obsidian/obsidian.json`
   - `opencode auth login`

6. **Quick checks**
   - `theme` shows `* everbloom`; `theme gruvbox` recolors border, Ghostty, Chrome, VS Code; `theme everbloom` back
   - Super+C/V pastes in Chrome; Alt+Shift switches to Arabic
   - `hyprctl monitors | grep 100` shows 100 Hz

7. **Arm the jobs** (only now; the old box is gone, single writer)
   ```bash
   loginctl enable-linger abdullah
   systemctl --user enable --now news-daily.timer news-weekly.timer news-x-collect.timer rai-maintenance.timer paper-portfolio.timer
   ~/helm/03-rai/skills/rai/scheduled/run-maintenance-ubuntu.sh   # dry run, should exit 0
   ```

8. Next morning: `ls ~/helm/08-bawaba/daily/ | tail -1` is today's digest. Then walk `checklist.md` phase 8 (plugins, cleanup) at leisure.

If `install.sh` fails midway: fix the cause and re-run it, it is idempotent.

## If the helm clone dies (`fatal: early EOF` / `fetch-pack: invalid index-pack output`)

helm is a ~930MB pack (mostly `13-archive/historical-sessions/*.json` and media blobs), and a single
HTTPS transfer can die mid-pack on flaky Wi-Fi:

```
error: 12692 bytes of body are still expected
fetch-pack: unexpected disconnect while reading sideband packet
fatal: early EOF
fatal: fetch-pack: invalid index-pack output
```

It is a dropped transfer, not corruption or an auth failure. `install.sh` step `[2/9]` handles this
itself:

1. If the hub (`linux`, this Omarchy desktop) is reachable over Tailscale, it clones `linux:helm`
   directly at LAN speed over the tailnet, then repoints `origin` at GitHub.
2. Otherwise it clones `--depth=1` from GitHub (small, rarely dies), then runs `git fetch --unshallow`
   in a bounded retry loop (5 attempts, 10s apart) so a dropped deepen just retries instead of
   restarting the whole clone from zero.

If all 5 unshallow attempts fail (no usable network at all), fix the network and re-run
`git -C ~/helm fetch --unshallow` by hand. On Ethernet with a flaky HTTP/2 middlebox, try
`git config --global http.version HTTP/1.1` first. Do not `--filter=blob:none` or sparse-checkout
the vault: Obsidian Sync and the hooks walk the full tree, and a lazy fetch on every `git log -p`
is worse than one slow clone.
