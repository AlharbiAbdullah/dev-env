#!/usr/bin/env bash
# install.sh — take a fresh Omarchy 4 box to the Ubuntu-box setup. Idempotent.
#   ./install.sh                 # everything
#   ENABLE_TIMERS=0 ./install.sh # stage without arming the scheduled jobs (cutover)
# Order: guard -> sudoers -> gh + helm -> packages -> configs -> fonts -> themes
#        -> dev tools -> claude -> system units + /etc -> timers (last).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
ENABLE_TIMERS="${ENABLE_TIMERS:-1}"
step() { echo; echo "== $*"; }

# --- guard: Omarchy 4 only ---
[ "$(uname -s)" = "Linux" ] || { echo "Linux only."; exit 1; }
command -v pacman >/dev/null || { echo "pacman not found: this targets Omarchy (Arch)."; exit 1; }
[ -d /usr/share/omarchy ] || { echo "/usr/share/omarchy missing: not an Omarchy 4 install."; exit 1; }
[ "$USER" = "abdullah" ] || echo "!! user is $USER, several units hardcode /home/abdullah"

# --- [1] sudoers ---
step "[1/9] sudoers"
sudo install -m 0440 "$HERE/etc/sudoers.d/ab" /etc/sudoers.d/ab

# --- [2] gh + helm ---
step "[2/9] GitHub auth + helm"
if ! gh auth status >/dev/null 2>&1; then gh auth login --web --git-protocol https; fi
[ -d "$HOME/helm/.git" ] || git clone https://github.com/AlharbiAbdullah/helm.git "$HOME/helm"

# --- [3] packages ---
step "[3/9] packages (pacman + AUR via omarchy pkg)"
pkgs=$(grep -vE '^\s*(#|$)' "$HERE/packages/pacman.txt" | sed 's/#.*//' | xargs)
omarchy-pkg-add $pkgs
aur=$(grep -vE '^\s*(#|$)' "$HERE/packages/aur.txt" | sed 's/#.*//' | xargs)
omarchy-pkg-aur-add $aur || echo "!! some AUR packages failed; re-run: omarchy pkg aur add $aur"
omarchy-install-terminal ghostty
omarchy-install-service-1password || true
sudo mkdir -p /etc/opt/chrome/policies/managed && sudo chmod a+rw /etc/opt/chrome/policies/managed
xdg-settings set default-web-browser google-chrome.desktop || true
mkdir -p "$HOME/.local/bin"
ln -sfn /usr/bin/cursor "$HOME/.local/bin/code"   # `code` opens Cursor (theme script targets /usr/bin/code for real VS Code)

# --- [4] configs ---
step "[4/9] configs"
mkdir -p "$HOME/.config" "$HOME/.local/bin"
cp "$HERE/.bashrc"      "$HOME/.bashrc"
cp "$HERE/.tmux.conf"   "$HOME/.tmux.conf"
cp "$HERE/starship.toml" "$HOME/.config/starship.toml"
cp -R "$HERE/config/." "$HOME/.config/"
chmod +x "$HOME/.config/omarchy/hooks/theme-set.d/rai-theme-set"
cp "$HERE/theme" "$HERE/theme-render" "$HERE/new-window" "$HERE/focus-mode" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin"/{theme,theme-render,new-window,focus-mode}
[ -d "$HOME/.tmux/plugins/tpm" ] || git clone -q https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
( cd "$HOME/.config/opencode" && [ -f package.json ] && command -v npm >/dev/null && npm i --silent ) || true

# --- [5] fonts ---
step "[5/9] fonts"
mkdir -p "$HOME/.local/share/fonts"
if ! fc-list | grep -qi "Cairo"; then
  curl -fsSL -o "$HOME/.local/share/fonts/Cairo[slnt,wght].ttf" \
    "https://github.com/google/fonts/raw/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf" && fc-cache -f
fi

# --- [6] themes ---
step "[6/9] themes (theme.lua -> Omarchy user themes)"
mkdir -p "$HOME/.config/themes"
cp -R "$REPO_ROOT/common/themes/." "$HOME/.config/themes/"
"$HOME/.local/bin/theme-render"
omarchy-theme-set everbloom || true

# --- [7] dev tools ---
step "[7/9] dev tools"
if [ ! -d "$HOME/.nvm" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"
nvm ls 24 >/dev/null 2>&1 || nvm install 24
nvm alias default 24 >/dev/null
npm ls -g @earendil-works/pi-coding-agent >/dev/null 2>&1 || npm i -g @earendil-works/pi-coding-agent
npm ls -g @openai/codex >/dev/null 2>&1 || npm i -g @openai/codex
[ -x "$HOME/.bun/bin/bun" ] || curl -fsSL https://bun.sh/install | bash
[ -x "$HOME/.opencode/bin/opencode" ] || curl -fsSL https://opencode.ai/install | bash
uv python install 3.12 >/dev/null 2>&1 || true
( cd "$HOME/helm/02-ana/financial/investment/paper-portfolio" 2>/dev/null && [ ! -d .venv ] && uv venv --python 3.12 -q && uv pip install -q yfinance pandas numpy curl_cffi ) || true

# --- [8] claude ---
step "[8/9] Claude Code"
[ -x "$HOME/.local/bin/claude" ] || curl -fsSL https://claude.ai/install.sh | bash
"$HERE/claude-config.sh"

# --- [9] system units, /etc, services, timers ---
step "[9/9] system: udev, polkit, ollama, groups, services, user units"
sudo install -m 0644 "$HERE/etc/udev/rules.d/99-xremap.rules" /etc/udev/rules.d/99-xremap.rules
sudo install -m 0644 "$HERE/etc/polkit-1/rules.d/99-1password-unlock.rules" /etc/polkit-1/rules.d/99-1password-unlock.rules
sudo install -d /etc/systemd/system/ollama.service.d
sudo install -m 0644 "$HERE/etc/systemd/system/ollama.service.d/expose.conf" /etc/systemd/system/ollama.service.d/expose.conf
sudo install -d /etc/systemd/system/ollama.service.d && printf '[Service]\nEnvironment="OLLAMA_IGPU_ENABLE=1"\n' | sudo tee /etc/systemd/system/ollama.service.d/igpu.conf >/dev/null
echo uinput | sudo tee /etc/modules-load.d/uinput.conf >/dev/null; sudo modprobe uinput || true
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null; sudo modprobe i2c-dev || true
for g in input i2c docker ollama; do getent group "$g" >/dev/null && ! id -nG "$USER" | grep -qw "$g" && sudo usermod -aG "$g" "$USER"; done
grep -q '^WIRELESS_REGDOM=' /etc/conf.d/wireless-regdom 2>/dev/null || echo 'WIRELESS_REGDOM="SA"' | sudo tee -a /etc/conf.d/wireless-regdom >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable --now docker tailscaled sshd ollama 2>/dev/null || true
sudo ufw allow 22/tcp >/dev/null 2>&1 || true; sudo ufw allow 11434/tcp >/dev/null 2>&1 || true   # sshd (Mac sync) + ollama on the tailnet
UNIT_DST="$HOME/.config/systemd/user"; mkdir -p "$UNIT_DST"
install -m 0644 "$HERE"/systemd/*.service "$HERE"/systemd/*.timer "$UNIT_DST/"
systemctl --user daemon-reload
TIMERS="news-daily news-weekly news-x-collect rai-maintenance paper-portfolio"
loginctl enable-linger "$USER" >/dev/null 2>&1 || true
if [ "$ENABLE_TIMERS" = "1" ]; then
  systemctl --user enable --now $(for u in $TIMERS; do printf '%s.timer ' "$u"; done)
  systemctl --user list-timers --all | grep -E 'news|rai|portfolio' || true
else
  echo "  ENABLE_TIMERS=0: units installed, NOT enabled. Arm after the old box's timers are off:"
  echo "    systemctl --user enable --now $(for u in $TIMERS; do printf '%s.timer ' "$u"; done)"
fi

cat <<MSG

== Done. Manual steps (logins cannot be scripted):
  1. Reboot once (groups, uinput, i2c-dev, xremap).
  2. tailscale up --ssh --hostname linux      (Mac pushes to linux:helm over Tailscale SSH)
  3. claude          -> browser login; then: claude plugin marketplace add jarrodwatts/claude-hud && claude plugin install claude-hud@claude-hud
  4. 1Password app sign-in, then Settings > Developer > SSH agent; gh auth status; opencode auth login
  5. Chrome: sign in, then log in to x.com, substack.com, medium.com (collectors read the Default profile cookies)
  6. Obsidian: open ~/helm, Settings > Sync re-pair, set "cli": true in ~/.config/obsidian/obsidian.json (app closed)
  7. restore-backup.sh   (creds, repos, docker volumes, ollama models) if not done already
  8. omarchy update; theme everbloom; verify with the checklist in helm/05-projects/kitchen/omarchy-migration/
MSG
