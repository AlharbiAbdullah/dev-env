#!/usr/bin/env bash
# Put the Omarchy agents panel on a cloned copy so it can carry marks for the
# harnesses beyond claude/codex/fireworks (pi, opencode, agy) and give the
# synthetic "AI" record its own model-only layout. The QML data logic stays
# symlinked to the packaged files so Omarchy updates still land; Panel.qml is a
# patched copy, re-applied here on every run (and by the post-update hook), so
# an update cannot strand the patch.
# Ruling 2026-10-02. Revert: omarchy plugin remove <user>.agents.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
STOCK="/usr/share/omarchy/shell/plugins/agents"
USERNAME="$(id -un)"
CLONE="$HOME/.config/omarchy/plugins/${USERNAME}.agents"

command -v omarchy >/dev/null || { echo "agents-panel-setup: omarchy not found" >&2; exit 1; }

if [ ! -d "$CLONE" ]; then
  omarchy plugin clone omarchy.agents >/dev/null
fi

ln -sfn "$STOCK/Main.qml" "$CLONE/Main.qml"
ln -sfn "$STOCK/Agent.qml" "$CLONE/Agent.qml"
install -m 0644 "$STOCK/Panel.qml" "$CLONE/Panel.qml"

python3 - "$CLONE/Panel.qml" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
source = path.read_text()


def patch(old, new, name):
    global source
    if old not in source:
        print(f"agents-panel-setup: patch anchor '{name}' missing; leaving that bit unpatched", file=sys.stderr)
        return
    source = source.replace(old, new, 1)


# A flag the AI record can raise to get a model-only layout.
patch(
    "  readonly property var provider: providers.length > 0 ? providers[providerIndex] : null",
    "  readonly property var provider: providers.length > 0 ? providers[providerIndex] : null\n"
    "  // The AI tab lists every model and nothing else: no hero, no limits, every row.\n"
    "  readonly property bool modelsOnly: !!provider && String(provider.providerId) === \"0-ai\"",
    "modelsOnly",
)
# No hero on the AI tab.
patch(
    "            id: hero\n            visible: !!root.provider",
    "            id: hero\n            visible: !!root.provider && !root.modelsOnly",
    "hero visibility",
)
# Every model row on the AI tab: top ten, and the panel keeps the same length as
# the other tabs instead of shrinking to the shorter model-only content.
patch(
    "    return rows.slice(0, 4)",
    "    var cap = (root.modelsOnly || !(root.provider && (root.provider.limits || []).length)) ? 10 : 4\n"
    "    return rows.slice(0, cap)",
    "model row cap",
)
# Five subscriptions no longer fit the stock equal-width cells: let each chip
# size to its label so the longest ("Claude Code") stops crowding its neighbour.
patch(
    "                width: providerSwitch.cellWidth\n                text: modelData.providerName",
    "                text: modelData.providerName",
    "chip width",
)
# The model-only tab keeps the full panel length instead of shrinking.
patch(
    "    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(640))",
    "    contentHeight: root.modelsOnly\n"
    "      ? panel.fittedContentHeight(Style.space(640), Style.space(640))\n"
    "      : panel.fittedContentHeight(column.implicitHeight, Style.space(640))",
    "panel height",
)

path.write_text(source)
PY

install -m 0644 "$HERE"/agents-panel/*.svg "$CLONE/assets/"

omarchy plugin enable "${USERNAME}.agents" >/dev/null 2>&1 || true
omarchy bar set "${USERNAME}.agents" providers \
  '{"claude":{"enabled":true},"codex":{"enabled":false},"fireworks":{"enabled":false}}' --json >/dev/null
