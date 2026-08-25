#!/usr/bin/env bash
# backup-ubuntu.sh — pre-wipe backup of the Ubuntu box to the Mac (over Tailscale SSH).
# Re-runnable: rsync parts are incremental, tar parts are overwritten.
#   ./backup-ubuntu.sh            # everything
#   ./backup-ubuntu.sh --light    # skip the heavy phase (docker volumes, multipass, ollama models)
# Destination: mac:~/backups/linux-<date>/
set -uo pipefail
DEST_HOST="${DEST_HOST:-mac}"
STAMP="${STAMP:-2026-08-25}"
DEST="backups/linux-$STAMP"
LIGHT=0; [ "${1:-}" = "--light" ] && LIGHT=1
R="rsync -aH --info=progress2 --no-inc-recursive"
log(){ echo "[$(date +%H:%M:%S)] $*"; }

ssh -o BatchMode=yes "$DEST_HOST" "mkdir -p ~/$DEST/{manifest,home,repos,system,heavy}" || { echo "cannot reach $DEST_HOST"; exit 1; }

# ---- P0 manifest ---------------------------------------------------------
log "P0 manifest"
M=$(mktemp -d)
apt-mark showmanual > "$M/apt-manual.txt"; dpkg -l > "$M/dpkg-l.txt"; snap list > "$M/snap.txt" 2>/dev/null
systemctl --user list-unit-files --state=enabled > "$M/user-units-enabled.txt"
systemctl --user list-timers --all > "$M/user-timers.txt"
systemctl list-unit-files --state=enabled > "$M/system-units-enabled.txt"
id > "$M/id.txt"; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID > "$M/lsblk.txt"; ip -br a > "$M/ip.txt"
hyprctl monitors > "$M/hyprctl-monitors.txt" 2>/dev/null; iw reg get > "$M/iw-reg.txt" 2>/dev/null
code --list-extensions > "$M/vscode-extensions.txt" 2>/dev/null; cursor --list-extensions > "$M/cursor-extensions.txt" 2>/dev/null
npm ls -g --depth=0 > "$M/npm-global.txt" 2>/dev/null; uv python list --only-installed > "$M/uv-python.txt" 2>/dev/null
ollama list > "$M/ollama-models.txt" 2>/dev/null; docker images > "$M/docker-images.txt" 2>/dev/null; docker volume ls > "$M/docker-volumes.txt" 2>/dev/null
multipass list > "$M/multipass.txt" 2>/dev/null; tailscale status > "$M/tailscale.txt" 2>/dev/null
crontab -l > "$M/crontab.txt" 2>&1; ls -la ~/.claude > "$M/claude-symlinks.txt"
sudo nmcli --show-secrets connection show Saad_5g > "$M/wifi-Saad_5g.txt" 2>/dev/null
sudo nmcli --show-secrets connection show Saad_2.4g > "$M/wifi-Saad_2.4g.txt" 2>/dev/null
$R "$M/" "$DEST_HOST:$DEST/manifest/"; rm -rf "$M"

# ---- P1 home: dotfiles, creds, state ------------------------------------
log "P1 home (dotfiles + credentials + app state)"
cd "$HOME"
$R -R --exclude 'google-chrome/Default/Service Worker' --exclude 'google-chrome/Default/Cache*' --exclude 'google-chrome/Default/Code Cache' \
  .bashrc .bashrc.local .tmux.conf .gitconfig .npmrc .claude.json \
  .ssh .gnupg .secrets .1password .ollama .duckdb \
  .config/1Password .config/gh .config/op .config/gcloud .config/doctl .config/tailscale \
  .config/themes .config/hypr .config/ghostty .config/xremap .config/micro .config/glow .config/git \
  .config/fastfetch .config/mako .config/rofi .config/waybar .config/starship.toml .config/tmux \
  .config/systemd .config/opencode .config/mimeapps.list .config/autostart .config/dconf \
  .config/obsidian .config/google-chrome/Default '.config/google-chrome/Local State' \
  .config/Code/User .config/Cursor/User .vscode/argv.json \
  .claude/.credentials.json .claude/keybindings.json .claude/themes .claude/settings.local.json \
  .claude/projects .claude/history.jsonl .claude/plugins/installed_plugins.json .claude/plugins/known_marketplaces.json \
  .pi/agent/auth.json .pi/agent/models-store.json .pi/agent/settings.json .pi/agent/rai-transcripts .pi/agent/sessions \
  .codex/config.toml .codex/auth.json .local/share/opencode/auth.json .local/share/keyrings \
  .local/bin/theme .local/bin/focus-mode .local/bin/new-window .local/share/fonts .local/state \
  .cursor/extensions/rai.rai-themes* \
  "$DEST_HOST:$DEST/home/" 2>&1 | grep -v 'No such file' | tail -3

# ---- P2 repos + work dirs -------------------------------------------------
log "P2 repos (helm, projects, dev-env, playground, work, staging)"
$R --exclude node_modules --exclude .venv --exclude __pycache__ --exclude .cache --exclude .pytest_cache \
  helm projects dev-env playground work staging "$DEST_HOST:$DEST/repos/" 2>&1 | tail -2

# ---- P3 system ------------------------------------------------------------
log "P3 system (/etc bits, tailscale, NetworkManager)"
sudo tar czf - /etc/sudoers.d/ab /etc/polkit-1/rules.d /etc/udev/rules.d /etc/modprobe.d \
  /etc/systemd/system/ollama.service /etc/systemd/system/ollama.service.d /etc/opt/chrome/policies \
  /etc/NetworkManager/system-connections /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/conf.d \
  /var/lib/tailscale /etc/ssh/sshd_config /etc/hostname /etc/hosts /etc/fstab 2>/dev/null \
  | ssh "$DEST_HOST" "cat > ~/$DEST/system/etc-and-state.tgz"

[ "$LIGHT" = 1 ] && { log "light mode: skipping heavy phase"; exit 0; }

# ---- P4 heavy: docker volumes, ollama models, multipass -------------------
log "P4 heavy: docker volumes"
for v in $(docker volume ls -q 2>/dev/null); do
  log "  volume $v"
  docker run --rm -v "$v":/v alpine tar cf - -C /v . | ssh "$DEST_HOST" "cat > ~/$DEST/heavy/docker-volume-$v.tar"
done
log "P4 heavy: ollama models (14 GB)"
sudo tar cf - /usr/share/ollama/.ollama/models 2>/dev/null | ssh "$DEST_HOST" "cat > ~/$DEST/heavy/ollama-models.tar"
log "P4 heavy: multipass VMs (62 GB)"
sudo tar cf - /var/snap/multipass/common/data/multipassd 2>/dev/null | ssh "$DEST_HOST" "cat > ~/$DEST/heavy/multipass.tar"
log "DONE"; ssh "$DEST_HOST" "du -sh ~/$DEST/*"
