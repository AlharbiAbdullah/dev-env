#!/usr/bin/env bash
# claude-config.sh — Claude Code config for this machine (mirrors the live layout).
# Reality: ~/.claude is a thin edge over the helm vault. Eight symlinks point into
# ~/helm/03-rai; the only real local files are keybindings.json, themes/, the
# credentials, and settings.local.json.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="$HOME/.claude"
RAI="$HOME/helm/03-rai"

# Skills: ONE symlink to the vault (2026-08-26). Omarchy's own skills
# (/usr/share/omarchy/default/agents/skills/*) are vendored into the vault as
# the /omarchy router, so nothing outside helm needs to be mounted. Omarchy
# pre-creates ~/.claude/skills and ~/.agents/skills as REAL dirs; `ln -sfn` onto
# a real dir drops the link inside it (skills/skills), so remove the dir first.
# A per-skill symlink farm was tried and rejected: it never picked up new skills.
link_skills() {
    local dest="$1"
    if [ -d "$dest" ] && [ ! -L "$dest" ]; then
        if find "$dest" -mindepth 1 ! -type l | grep -q .; then
            echo "  !! $dest holds real files; move them out, then re-run." >&2
            return 1
        fi
        rm -rf "$dest"
    fi
    ln -sfn "$RAI/skills" "$dest"
}

mkdir -p "$CLAUDE/themes"

if [ ! -d "$RAI" ]; then
    echo "  !! $RAI missing — clone helm first (bootstrap.sh does this)."
    exit 1
fi

# Symlinks into the vault (live layout, 2026-08).
ln -sfn "$RAI/agents"                 "$CLAUDE/agents"
ln -sfn "$RAI/hooks"                  "$CLAUDE/hooks"
link_skills "$CLAUDE/skills"
ln -sfn "$RAI/memory"                 "$CLAUDE/memory"
ln -sfn "$RAI/CLAUDE.md"              "$CLAUDE/CLAUDE.md"
ln -sfn "$RAI/config/settings.json"   "$CLAUDE/settings.json"
ln -sfn "$RAI/config/mcp.json"        "$CLAUDE/mcp.json"
ln -sfn "$RAI/config/statusline.sh"   "$CLAUDE/statusline.sh"
echo "  ~/.claude/{agents,hooks,skills,memory,CLAUDE.md,settings.json,mcp.json,statusline.sh} -> helm/03-rai"

# Real local files.
cp "$HERE/claude/keybindings.json"       "$CLAUDE/keybindings.json"
cp "$HERE/claude/themes/dim-select.json" "$CLAUDE/themes/dim-select.json"
if [ ! -f "$CLAUDE/settings.local.json" ]; then
    cp "$HERE/claude/settings.local.json" "$CLAUDE/settings.local.json"
    echo "  ~/.claude/settings.local.json (seeded)"
fi

# pi + opencode edges (same vault, same skills).
mkdir -p "$HOME/.pi/agent/extensions" "$HOME/.agents"
ln -sfn "$RAI/AGENTS.md"                "$HOME/.pi/agent/AGENTS.md"
ln -sfn "$RAI/harness/pi/rai-bridge.ts" "$HOME/.pi/agent/extensions/rai-bridge.ts"
link_skills "$HOME/.agents/skills"
echo "  ~/.pi/agent/{AGENTS.md,extensions/rai-bridge.ts}, ~/.agents/skills -> helm/03-rai"

echo "  Claude config done. Run 'claude' once to authenticate (browser login),"
echo "  then: claude plugin marketplace add jarrodwatts/claude-hud && claude plugin install claude-hud@claude-hud"
