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

mkdir -p "$CLAUDE/themes"

if [ ! -d "$RAI" ]; then
    echo "  !! $RAI missing — clone helm first (bootstrap.sh does this)."
    exit 1
fi

# Symlinks into the vault (live layout, 2026-08).
ln -sfn "$RAI/hooks"                  "$CLAUDE/hooks"
# Job scripts and the git credential helper name these paths; `omarchy update` removed them on 2026-11-05.
mkdir -p "$HOME/.local/bin"
for tool in claude gh; do ln -sfn "$HOME/.local/share/mise/shims/$tool" "$HOME/.local/bin/$tool"; done
# Claude Code owns ~/.claude/skills (claude.ai sync writes there): a real local folder, never the vault.
[ -L "$CLAUDE/skills" ] && rm "$CLAUDE/skills"
mkdir -p "$CLAUDE/skills"
ln -sfn "$RAI/harness/claude-code/user-instructions.md"              "$CLAUDE/CLAUDE.md"
ln -sfn "$RAI/config/settings.json"   "$CLAUDE/settings.json"
echo "  ~/.claude/{hooks,CLAUDE.md,settings.json} -> helm/03-rai"

# Auto-memory belongs to Claude Code, which keeps its own folder per project. Older installs linked
# helm's folder into the vault: drop that link so the tool makes a real folder again.
MEM="$CLAUDE/projects/-home-abdullah-helm/memory"
if [ -L "$MEM" ]; then
    rm "$MEM"
    echo "  removed the old auto-memory link: ~/.claude/projects/-home-abdullah-helm/memory"
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

# pi + opencode edges (same vault).
mkdir -p "$HOME/.pi/agent/extensions"
ln -sfn "$RAI/AGENTS.md"                "$HOME/.pi/agent/AGENTS.md"
ln -sfn "$RAI/harness/pi/rai-bridge.ts" "$HOME/.pi/agent/extensions/rai-bridge.ts"
[ -L "$HOME/.pi/agent/prompts" ] && rm "$HOME/.pi/agent/prompts"
ln -sfn "$HERE/pi/models.json"         "$HOME/.pi/agent/models.json"   # Ollama cloud models
ln -sfn "$HERE/pi/mcp.json"            "$HOME/.pi/agent/mcp.json"      # Context7, as in ~/.claude.json
# Merge portable defaults: model, the Ctrl+P scope (sol + Ollama, no pay-per-use OpenRouter) and
# a filter that hides everything in ~/.pi/agent/skills (Omarchy migrations drop stock links there).
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
[ -L "$HOME/.agents/skills" ] && rm "$HOME/.agents/skills"
echo "  ~/.pi/agent/{AGENTS.md,extensions/rai-bridge.ts} -> helm/03-rai; {models,mcp}.json -> dev-env"
mkdir -p "$HOME/.config/opencode/plugin"
ln -sfn "$RAI/AGENTS.md"                "$HOME/.config/opencode/AGENTS.md"
ln -sfn "$RAI/harness/opencode/rai.ts"  "$HOME/.config/opencode/plugin/rai.ts"
echo "  ~/.config/opencode/{AGENTS.md,plugin/rai.ts} -> helm/03-rai"
AGY_PLUGIN="$HOME/.gemini/config/plugins/rai"
mkdir -p "$AGY_PLUGIN"
ln -sfn "$RAI/AGENTS.md"                "$HOME/.gemini/GEMINI.md"
ln -sfn "$RAI/harness/agy/plugin.json"  "$AGY_PLUGIN/plugin.json"
ln -sfn "$RAI/harness/agy/hooks.json"   "$AGY_PLUGIN/hooks.json"
[ -L "$AGY_PLUGIN/skills" ] && rm "$AGY_PLUGIN/skills"
"$RAI/harness/agy/agy-hook.py" render-rules "$AGY_PLUGIN" || true   # agy re-renders at its first turn anyway
echo "  ~/.gemini/{GEMINI.md,config/plugins/rai} -> helm/03-rai"
mkdir -p "$HOME/.codex"
ln -sfn "$RAI/harness/codex/hooks.json" "$HOME/.codex/hooks.json"
grep -q '^\[mcp_servers.context7\]' "$HOME/.codex/config.toml" 2>/dev/null \
  || codex mcp add context7 -- npx -y @upstash/context7-mcp@latest   # context7 in every harness
echo "  ~/.codex/hooks.json -> helm/03-rai (Rai's hooks: start codex once and trust them)"

echo "  Claude config done. Run 'claude' once to authenticate (browser login),"
echo "  then: claude plugin marketplace add jarrodwatts/claude-hud && claude plugin install claude-hud@claude-hud"
