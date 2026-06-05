#!/usr/bin/env bash
# link-claude.sh — recreates ~/.claude symlinks pointing into Brain/PAI
# Prerequisite: ~/Brain must already be cloned on this machine.
#
# This mirrors the Mac setup where ~/.claude/ is a thin shell of symlinks
# pointing into ~/Brain/05_agent_brain/PAI/ so a single source of truth
# (Brain) drives the Claude Code config on every machine.

set -e

PAI="$HOME/Brain/05_agent_brain/PAI"
CLAUDE="$HOME/.claude"

if [ ! -d "$PAI" ]; then
    echo "ERROR: $PAI does not exist."
    echo "Clone Brain first, then re-run this script."
    exit 1
fi

mkdir -p "$CLAUDE"

ln -sfn "$PAI/CLAUDE.md"     "$CLAUDE/CLAUDE.md"
ln -sfn "$PAI/agents"        "$CLAUDE/agents"
ln -sfn "$PAI/commands"      "$CLAUDE/commands"
ln -sfn "$PAI/hooks"         "$CLAUDE/hooks"
ln -sfn "$PAI/mcp.json"      "$CLAUDE/mcp.json"
ln -sfn "$PAI/MEMORY"        "$CLAUDE/MEMORY"
ln -sfn "$PAI/settings.json" "$CLAUDE/settings.json"
ln -sfn "$PAI/skills"        "$CLAUDE/skills"
ln -sfn "$PAI/statusline.sh" "$CLAUDE/statusline.sh"

echo "Done. Symlinks created in $CLAUDE:"
ls -la "$CLAUDE" | grep -E '\->' || true
