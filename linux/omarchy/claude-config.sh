#!/usr/bin/env bash
# claude-config.sh — Claude Code config for this machine (mirrors the live layout).
# Reality: ~/.claude is a thin edge over the helm vault. Eight symlinks point into
# ~/helm/03-rai; the only real local files are keybindings.json, themes/, the
# credentials, and settings.local.json.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="$HOME/.claude"
RAI="$HOME/helm/03-rai"

# Skills merge: on Omarchy, ~/.claude/skills and ~/.agents/skills already exist as
# real dirs holding omarchy's own skills. `ln -sfn <dir> <existing-real-dir>` does
# NOT replace them: it exits 0 and drops the link *inside*, giving skills/skills.
# Link each vault skill individually so both sets live side by side.
link_skills() {
    local dest="$1"
    mkdir -p "$dest"
    rm -f "$dest/skills"
    local s
    for s in "$RAI/skills"/*; do
        [ -e "$s" ] || continue
        ln -sfn "$s" "$dest/$(basename "$s")"
    done
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
