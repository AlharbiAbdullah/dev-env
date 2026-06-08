#!/usr/bin/env bash
# claude-config.sh — Claude Code config for this machine.
# Replaces the old link-claude.sh (which pointed at a non-existent ~/brain/...PAI).
# Reality: ~/.claude/skills is a symlink into the helm vault; settings are real
# files seeded from this repo only when absent (local edits / credentials kept).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="$HOME/.claude"
SKILLS_SRC="$HOME/helm/03-rai/skills"

mkdir -p "$CLAUDE"

# Skills live in the helm vault — the only symlink in the real setup.
if [ -d "$SKILLS_SRC" ]; then
    ln -sfn "$SKILLS_SRC" "$CLAUDE/skills"
    echo "  ~/.claude/skills -> $SKILLS_SRC"
else
    echo "  !! $SKILLS_SRC missing — clone helm first (bootstrap.sh does this)."
fi

# Seed settings only if absent (never clobber local drift or credentials).
if [ ! -f "$CLAUDE/settings.json" ]; then
    cp "$HERE/claude/settings.json" "$CLAUDE/settings.json"
    echo "  ~/.claude/settings.json (seeded)"
fi
if [ ! -f "$CLAUDE/settings.local.json" ]; then
    cp "$HERE/claude/settings.local.json" "$CLAUDE/settings.local.json"
    echo "  ~/.claude/settings.local.json (seeded)"
fi

echo "  Claude config done. Run 'claude' once to authenticate (browser login)."
