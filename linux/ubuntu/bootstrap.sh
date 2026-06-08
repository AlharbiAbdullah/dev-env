#!/usr/bin/env bash
# bootstrap.sh — one-shot, idempotent rebuild of the Ubuntu dev environment.
# Safe to re-run. Prompts only for secrets/login. Order is deliberate:
#   privileges -> repos -> packages -> dotfiles -> claude -> timers (last).
#
# Usage:
#   ./bootstrap.sh [--hyprland-ppa]
#   ENABLE_TIMERS=0 ./bootstrap.sh   # stage a NEW machine without arming the
#                                    # scheduled jobs yet (migration cutover; see MIGRATION.md)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ENABLE_TIMERS="${ENABLE_TIMERS:-1}"
PPA_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --hyprland-ppa) PPA_ARGS+=("--hyprland-ppa") ;;
        -h|--help) echo "Usage: $0 [--hyprland-ppa]   (ENABLE_TIMERS=0 stages without arming timers)"; exit 0 ;;
        *) echo "Unknown arg: $arg (try --help)"; exit 1 ;;
    esac
done

# --- guards ---
[ "$(uname -s)" = "Linux" ] || { echo "Linux only."; exit 1; }
command -v apt-get >/dev/null 2>&1 || { echo "Needs apt (Ubuntu/Debian)."; exit 1; }

echo "=============================================="
echo " Ubuntu one-shot bootstrap  (ENABLE_TIMERS=$ENABLE_TIMERS)"
echo "=============================================="

# ---------------------------------------------------------------------------
# [1/6] NOPASSWD sudoers — validated so a bad line can never break sudo
# ---------------------------------------------------------------------------
echo ""; echo "[1/6] sudoers (NOPASSWD)"
SUDO_SRC="$HERE/sudoers/ab"; SUDO_DST="/etc/sudoers.d/ab"
if sudo cmp -s "$SUDO_SRC" "$SUDO_DST" 2>/dev/null; then
    echo "  already installed (identical) — skip"
else
    tmp="$(mktemp)"
    install -m 0440 "$SUDO_SRC" "$tmp"
    if sudo visudo -cf "$tmp" >/dev/null; then
        sudo install -o root -g root -m 0440 "$tmp" "$SUDO_DST"
        sudo visudo -c >/dev/null
        echo "  installed $SUDO_DST (validated)"
    else
        echo "  FATAL: sudoers candidate invalid — NOT installing."; rm -f "$tmp"; exit 1
    fi
    rm -f "$tmp"
fi

# ---------------------------------------------------------------------------
# [2/6] GitHub auth + clone repos (helm must exist before timers reference it)
# ---------------------------------------------------------------------------
echo ""; echo "[2/6] repos (helm, mirsad)"
if ! command -v gh >/dev/null 2>&1; then
    sudo apt-get update -qq && sudo apt-get install -y gh
fi
if ! gh auth status >/dev/null 2>&1; then
    echo "  GitHub login required:"
    gh auth login
fi
clone_repo () {  # url dest branch
    local url="$1" dest="$2" branch="${3:-}"
    if [ ! -d "$dest/.git" ]; then
        echo "  cloning $url -> $dest"
        git clone "$url" "$dest"
    else
        echo "  $dest already a git repo — skip clone"
    fi
    if [ -n "$branch" ] && git -C "$dest" rev-parse --verify "$branch" >/dev/null 2>&1; then
        git -C "$dest" checkout "$branch" >/dev/null 2>&1 || true
    fi
}
clone_repo https://github.com/AlharbiAbdullah/helm.git   "$HOME/helm"        main
mkdir -p "$HOME/work"
clone_repo https://github.com/AlharbiAbdullah/mirsad.git "$HOME/work/mirsad" prod

# ---------------------------------------------------------------------------
# [3/6] apt repos + packages + obsidian + snaps
# ---------------------------------------------------------------------------
echo ""; echo "[3/6] packages"
"$HERE/packages/apt-repos.sh" "${PPA_ARGS[@]}"

mapfile -t PKGS < <(grep -vE '^[[:space:]]*(#|$)' "$HERE/packages/apt.txt")
echo "  installing ${#PKGS[@]} apt packages..."
if ! sudo apt-get install -y "${PKGS[@]}"; then
    echo "  batch failed — retrying one-by-one so a single bad pkg doesn't block the rest"
    for p in "${PKGS[@]}"; do
        sudo apt-get install -y "$p" || echo "  WARN: failed to install $p"
    done
fi

# obsidian — not in any apt repo; fetch the latest .deb from GitHub releases
if ! dpkg -s obsidian >/dev/null 2>&1; then
    echo "  installing obsidian (.deb from GitHub releases)..."
    ob_tmp="$(mktemp -d)"
    ob_ver="$(curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | jq -r .tag_name | sed 's/^v//')"
    if [ -n "$ob_ver" ] && [ "$ob_ver" != "null" ] \
        && curl -fsSL -o "$ob_tmp/obsidian.deb" \
            "https://github.com/obsidianmd/obsidian-releases/releases/download/v${ob_ver}/obsidian_${ob_ver}_amd64.deb"; then
        sudo apt-get install -y "$ob_tmp/obsidian.deb" || echo "  WARN: obsidian install failed (install manually later)"
    else
        echo "  WARN: could not fetch obsidian .deb (install manually later)"
    fi
    rm -rf "$ob_tmp"
fi

# snaps (user-chosen only; bases are pulled automatically)
if command -v snap >/dev/null 2>&1; then
    while read -r s; do
        [ -z "$s" ] && continue
        case "$s" in \#*) continue ;; esac
        snap list "$s" >/dev/null 2>&1 || sudo snap install "$s"
    done < "$HERE/packages/snap.txt"
fi

# ---------------------------------------------------------------------------
# [4/6] dotfiles, fonts, tools (delegates to the existing copy-model setup.sh)
# ---------------------------------------------------------------------------
echo ""; echo "[4/6] dotfiles + fonts + tools (setup.sh)"
"$HERE/setup.sh" "${PPA_ARGS[@]}"

# ---------------------------------------------------------------------------
# [5/6] Claude Code
# ---------------------------------------------------------------------------
echo ""; echo "[5/6] Claude Code"
if ! command -v claude >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/claude" ]; then
    "$HERE/install-claude.sh"
fi
"$HERE/claude-config.sh"

# ---------------------------------------------------------------------------
# [6/6] systemd user timers (LAST — ExecStart points at ~/helm, which now exists)
# ---------------------------------------------------------------------------
echo ""; echo "[6/6] scheduled jobs (systemd user timers)"
UNIT_DST="$HOME/.config/systemd/user"; mkdir -p "$UNIT_DST"
for u in news-daily news-weekly rai-maintenance; do
    install -m 0644 "$HERE/systemd/$u.service" "$UNIT_DST/$u.service"
    install -m 0644 "$HERE/systemd/$u.timer"   "$UNIT_DST/$u.timer"
done
systemctl --user daemon-reload
if [ "$ENABLE_TIMERS" = "1" ]; then
    systemctl --user enable --now news-daily.timer news-weekly.timer rai-maintenance.timer
    loginctl enable-linger "$USER" >/dev/null 2>&1 || true
    echo "  timers enabled + lingering on:"
    systemctl --user list-timers --all | grep -E 'news|rai' || true
else
    echo "  ENABLE_TIMERS=0 — units installed but NOT enabled (cutover staging)."
    echo "  Arm later (after disabling the OLD machine's timers — see MIGRATION.md):"
    echo "    systemctl --user enable --now news-daily.timer news-weekly.timer rai-maintenance.timer"
    echo "    loginctl enable-linger $USER"
fi

echo ""
echo "=============================================="
echo " Bootstrap complete."
echo "=============================================="
cat <<EOF
Next:
  1. Log out, pick "Hyprland" in GDM, log back in.
  2. Secrets:  cp "$HERE/.bashrc.local.example" ~/.bashrc.local   # then fill in real keys
  3. Run 'claude' once to authenticate.
  4. In WezTerm: run tmux, press prefix + I to install tmux plugins.
  5. Machine-to-machine cutover (timers + ChromaDB single-writer): see "$HERE/MIGRATION.md"
EOF
