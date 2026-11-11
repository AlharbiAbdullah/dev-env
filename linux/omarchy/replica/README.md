# ARM replica

How to rebuild the M3 Pro laptop (J514S) as the hub's replica. `install.sh` is x86_64 only.
Last run 2026-11-05 on Omarchy 4.5.0-3, stable channel. The hub stays the only producer.

| File | Goes to |
|---|---|
| `machine.json` | `~/.config/rai/machine.json` on the laptop |
| `etc/modprobe.d/asahi-g15.conf` | `/etc/modprobe.d/` on the laptop |
| `hub-ssh.conf` | included by `~/.ssh/config` on the hub |
| `hub-systemd/syncthing-replica-tunnel.service` | `~/.config/systemd/user/` on the hub |

## 1. Install Omarchy

Use the official Omarchy Installer from macOS, channel Stable. To start over, use
**Installation → Remove Omarchy…** first. The installer needs macOS 15 or newer.

## 2. Sign-ins, on the laptop

1. Run `omarchy-install-service-1password` and sign in.
2. In **Settings → Developer**, enable **Integrate with 1Password CLI** and **Use the SSH agent**.
3. Copy the hub's `~/.config/1Password/ssh/agent.toml` once SSH works. The `github` key lives in
   the `Abdullah` vault, and the agent serves only `Private` by default.
4. Sign in to Google, GitHub and Claude in Chrome.

## 3. Reach it from the hub

```bash
sudo hostnamectl set-hostname omarchy-laptop
omarchy-install-service-tailscale            # sign in with GitHub, not Google
omarchy-setup-security-sshd --gh-keys AlharbiAbdullah
tailscale set --ssh --operator=$USER         # the hub's scheduled sync logs in with no key
```

On the hub, remove the old `omarchy-laptop` host key from `known_hosts`, add the new one, and
test `ssh replica`.

## 4. GPU

Check first: `journalctl -k -b | grep asahi-g15`. Add the override only if the driver still
refuses this firmware hash (upstream: `omacom/linux-aurora` issue 247).

```bash
sudo install -m 644 etc/modprobe.d/asahi-g15.conf /etc/modprobe.d/
sudo mkinitcpio -P && sudo omarchy-mac-boot-update
sudo omarchy-apple-silicon-boot-check        # must exit 0 before the reboot
```

Delete the file and repeat the rebuild once upstream pins the hash.

## 5. Home folders

1. On the laptop: `sudo pacman -S syncthing`, then `systemctl --user enable --now syncthing`.
2. Turn off global discovery, local discovery and relays, as on the hub.
3. Add the hub as a device. Copy each folder's `.stignore` from the hub, then add the folders:
   `dev-env keep personal playground projects work`.
4. On the hub, replace the old laptop device with the new ID at `tcp://127.0.0.1:22200`, and share
   the six folders with it.
5. On the hub: `systemctl --user enable --now syncthing-replica-tunnel`.
6. Live config: folder `config` at `~/.config`, send-only on the hub and receive-only on the
   laptop. `~/.config/.stignore` is an allow-list, identical on both machines: only the `!/name`
   lines sync, and the last line `*` ignores the rest. Copy it from the hub before adding the
   folder, and seed the listed files with `rsync -a` first so the laptop starts identical.

## 6. Vault

The hub ships it over SSH, as the coordinator does:

```bash
ssh replica 'git init -q -b main ~/helm'
rsync -a ~/helm/.git/objects/ replica:helm/.git/objects/
head=$(git -C ~/helm rev-parse HEAD)
ssh replica "cd ~/helm && git update-ref refs/remotes/hub/main $head && git checkout -q -f -B main refs/remotes/hub/main"
ssh replica 'git -C ~/helm remote add origin https://github.com/AlharbiAbdullah/helm.git'
```

## 7. Harnesses

On the laptop, once `dev-env` and the vault have landed:

```bash
~/dev-env/linux/omarchy/claude-config.sh
mise install opencode antigravity-cli pi
cd ~/helm
uv sync --script 12-system/engine/cli/rai
(cd 12-system/engine/host && uv sync)
(cd 12-system/engine/cli && uv sync)
03-rai/semantic-memory/scripts/py-chroma.sh -c "import chromadb"
```

Copy the hub's `~/.local/bin/rai` wrapper to the same path, and the hub's
`~/.cache/chroma/onnx_models` to the same path. Hooks and `rai` run uv with `--offline`, so their
dependencies must be cached first.

## 8. Mirror the desktop

The desktop's live setup is the source of truth. Copy from its live files, which can be newer than
this repo: `~/.bashrc`, `~/.bashrc.local`, `~/.config` (theme, shell, editors, `mise`, Chrome flags,
`mimeapps.list`), web apps, scripts, packages and editor extensions. Remove apps the desktop does not
have, and enable `docker`, `ollama`, `paccache.timer` and `agents-local.timer`.

The laptop differs only here:

| Item | Laptop |
|---|---|
| Kernel, firmware, Mesa, Mac packages | Keep the installed ARM set |
| `hypr/monitors.lua` | Keep the laptop's |
| Hub jobs (news, maintenance, backup, portfolio) | Off: the hub is the sole producer |
| Sign-ins | Per machine |
| Island bar | In `shell.json`: move `center` to the start of `right`, set `centerAnchor` to `""`, the clock `format` to `ddd d  h:mm AP` and the active window's `maxWidth` to 480, so nothing sits under the notch |
| xremap | No ARM AUR package: official `aarch64-hypr` binary at `/usr/local/bin/xremap`, with `systemd/xremap.service` here. Also needs `etc/udev/rules.d/99-xremap.rules`, the `uinput` module, the `input` group and a new login |
| `pipewire-jack` | Skipped: conflicts with `jack2` |
| `dbeaver`, `harper`, `docker-sbx` | Not in the ARM repos |
