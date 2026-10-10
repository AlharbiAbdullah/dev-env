#!/usr/bin/env bash
# claude-config.sh — Claude Code config for this machine (mirrors the live layout).
# Reality: ~/.claude is a thin edge over the helm vault. Five symlinks point into
# ~/helm/03-rai, and agents/ holds rendered links; the only real local files are keybindings.json, themes/, the
# credentials, and settings.local.json. The Context7 MCP server is registered at user
# scope in ~/.claude.json, and the status line is the claude-hud plugin.
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
# agents is a real folder of links to the agents a session may spawn: never the router
# or the tutor (03-rai/harness/claude-code/render_agents.py replaces an old folder link).
uv run "$RAI/harness/claude-code/render_agents.py"
ln -sfn "$RAI/hooks"                  "$CLAUDE/hooks"
link_skills "$CLAUDE/skills"
ln -sfn "$RAI/harness/claude-code/user-instructions.md"              "$CLAUDE/CLAUDE.md"
ln -sfn "$RAI/config/settings.json"   "$CLAUDE/settings.json"
echo "  ~/.claude/{hooks,skills,CLAUDE.md,settings.json} -> helm/03-rai; agents rendered"

# Auto-memory store: Claude Code keys it by project path (~/helm -> -home-abdullah-helm). The notes
# live in the vault (2026-09-26) so git backs them up and every machine shares one store. A real
# dir here holds this machine's own notes: merge them into the vault by hand, never clobber them.
MEM="$CLAUDE/projects/-home-abdullah-helm/memory"
mkdir -p "$(dirname "$MEM")"
if [ -d "$MEM" ] && [ ! -L "$MEM" ]; then
    echo "  !! $MEM is a real dir: merge its notes into $RAI/auto-memory, move it aside, re-run." >&2
else
    ln -sfn "$RAI/auto-memory" "$MEM"
    echo "  ~/.claude/projects/-home-abdullah-helm/memory -> helm/03-rai/auto-memory"
fi

# Context7 MCP server at user scope (~/.claude.json, where Claude Code reads MCP servers).
# Idempotent: skipped when already registered.
if command -v claude >/dev/null 2>&1; then
    claude mcp get context7 >/dev/null 2>&1 || claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest
    echo "  context7 MCP registered at user scope (~/.claude.json)"
else
    echo "  claude is not on PATH yet: re-run this script after installing it to register Context7."
fi

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
ln -sfn "$RAI/harness/pi/prompts"      "$HOME/.pi/agent/prompts"        # /recall, /remember
ln -sfn "$HERE/pi/models.json"         "$HOME/.pi/agent/models.json"   # Ollama cloud models
ln -sfn "$HERE/pi/mcp.json"            "$HOME/.pi/agent/mcp.json"      # Context7, as in ~/.claude.json
# Merge portable defaults: model, the Ctrl+P scope (sol + Ollama, no pay-per-use OpenRouter) and
# a filter that hides everything in ~/.pi/agent/skills. Omarchy migrations drop stock omarchy and
# diagnose-crash links there; pi loads that dir before ~/.agents/skills, so they shadowed Rai's
# /omarchy router. Rai's skills live only in ~/.agents/skills, as ~/.claude/skills for Claude.
# Keep this machine's packages, theme and device ID.
PI_SETTINGS="$HOME/.pi/agent/settings.json"
if [ -f "$PI_SETTINGS" ]; then
    PI_SETTINGS_TMP="$(mktemp "$HOME/.pi/agent/settings.XXXXXX")"
    jq --slurpfile defaults "$HERE/pi/settings.json" '. * $defaults[0]' \
        "$PI_SETTINGS" > "$PI_SETTINGS_TMP"
    mv "$PI_SETTINGS_TMP" "$PI_SETTINGS"
else
    install -m 0600 "$HERE/pi/settings.json" "$PI_SETTINGS"
fi
link_skills "$HOME/.agents/skills"
echo "  ~/.pi/agent/{AGENTS.md,extensions/rai-bridge.ts}, ~/.agents/skills -> helm/03-rai; {models,mcp}.json -> dev-env"
mkdir -p "$HOME/.config/opencode/plugin"
ln -sfn "$RAI/AGENTS.md"                "$HOME/.config/opencode/AGENTS.md"
ln -sfn "$RAI/harness/opencode/rai.ts"  "$HOME/.config/opencode/plugin/rai.ts"
echo "  ~/.config/opencode/{AGENTS.md,plugin/rai.ts} -> helm/03-rai"
AGY_PLUGIN="$HOME/.gemini/config/plugins/rai"
mkdir -p "$AGY_PLUGIN"
ln -sfn "$RAI/AGENTS.md"                "$HOME/.gemini/GEMINI.md"
ln -sfn "$RAI/harness/agy/plugin.json"  "$AGY_PLUGIN/plugin.json"
ln -sfn "$RAI/harness/agy/hooks.json"   "$AGY_PLUGIN/hooks.json"
ln -sfn "$RAI/skills"                   "$AGY_PLUGIN/skills"
"$RAI/harness/agy/agy-hook.py" render-rules "$AGY_PLUGIN" || true   # agy re-renders at its first turn anyway
echo "  ~/.gemini/{GEMINI.md,config/plugins/rai} -> helm/03-rai"
mkdir -p "$HOME/.codex"
ln -sfn "$RAI/harness/codex/hooks.json" "$HOME/.codex/hooks.json"
echo "  ~/.codex/hooks.json -> helm/03-rai (the coding rules; trust the hook once in codex)"

echo "  Claude config done. Run 'claude' once to authenticate (browser login),"
echo "  then: claude plugin marketplace add jarrodwatts/claude-hud && claude plugin install claude-hud@claude-hud"
