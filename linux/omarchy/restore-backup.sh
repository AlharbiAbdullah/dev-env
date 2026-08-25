#!/usr/bin/env bash
# restore-backup.sh — pull the pre-wipe backup back from the Mac onto the fresh Omarchy box.
#   ./restore-backup.sh            # creds + dotfiles + repos + system state
#   ./restore-backup.sh --heavy    # also ollama models (otherwise: ollama pull gpt-oss:20b bge-m3)
# Never restores: Chrome cookies (keyring-bound, re-login), OAuth tokens for opencode/codex (re-login per machine).
set -uo pipefail
SRC_HOST="${SRC_HOST:-mac}"; STAMP="${STAMP:-2026-08-25}"; SRC="backups/linux-$STAMP"
HEAVY=0; [ "${1:-}" = "--heavy" ] && HEAVY=1
R="rsync -aH --info=progress2"
log(){ echo "[$(date +%H:%M:%S)] $*"; }

log "home: credentials, dotfiles, app state"
$R --exclude '.config/google-chrome' --exclude '.local/share/opencode/auth.json' --exclude '.codex/auth.json' \
   "$SRC_HOST:$SRC/home/" "$HOME/"
# Chrome: profile without cookies/logins (extensions + prefs survive; sessions need re-login)
$R --exclude 'Default/Cookies*' --exclude 'Default/Login Data*' --exclude 'Default/Web Data*' \
   "$SRC_HOST:$SRC/home/.config/google-chrome/" "$HOME/.config/google-chrome/"

# The home rsync brings back Ubuntu-era versions of the files install.sh manages
# (theme wrapper, ghostty/fastfetch configs, .bashrc); re-apply the Omarchy layer on top.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log "re-apply Omarchy layer over restored dotfiles"
cp "$HERE/.bashrc" "$HOME/.bashrc"; cp "$HERE/.tmux.conf" "$HOME/.tmux.conf"; cp "$HERE/starship.toml" "$HOME/.config/starship.toml"
cp -R "$HERE/config/." "$HOME/.config/"; chmod +x "$HOME/.config/omarchy/hooks/theme-set.d/rai-theme-set"
cp "$HERE/theme" "$HERE/theme-render" "$HERE/new-window" "$HERE/focus-mode" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin"/{theme,theme-render,new-window,focus-mode}

log "repos + work dirs"
for d in helm projects dev-env playground work staging; do
  $R "$SRC_HOST:$SRC/repos/$d/" "$HOME/$d/"
done

log "system state (/etc bits, tailscale identity, wifi)"
ssh "$SRC_HOST" "cat ~/$SRC/system/etc-and-state.tgz" > /tmp/etc-and-state.tgz
sudo systemctl stop tailscaled 2>/dev/null
sudo tar xzf /tmp/etc-and-state.tgz -C / var/lib/tailscale etc/NetworkManager/system-connections 2>/dev/null
sudo chmod 600 /etc/NetworkManager/system-connections/* 2>/dev/null
sudo systemctl start tailscaled NetworkManager 2>/dev/null
rm -f /tmp/etc-and-state.tgz
mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"; chmod 600 "$HOME/.ssh"/id_* "$HOME/.ssh"/spot-bot "$HOME/.ssh"/google_compute_engine 2>/dev/null

[ "$HEAVY" = 1 ] || { log "done (light). --heavy also restores ollama models"; exit 0; }

log "ollama models"
ssh "$SRC_HOST" "cat ~/$SRC/heavy/ollama-models.tar" | sudo tar xf - -C /tmp usr/share/ollama/.ollama/models 2>/dev/null \
  && sudo rsync -a /tmp/usr/share/ollama/.ollama/models/ /var/lib/ollama/models/ && sudo chown -R ollama:ollama /var/lib/ollama && sudo rm -rf /tmp/usr
log "done (heavy)."
