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
# A wider panel on every tab (the same width everywhere, so nothing jumps), so
# four subscription cards sit two by two with room for a meter on each line.
patch(
    "    contentWidth: panel.fittedContentWidth(Style.space(380))",
    "    contentWidth: panel.fittedContentWidth(Style.space(480))",
    "panel width",
)
# A limit carries the subscription and plan it belongs to through to the cards.
patch(
    "      if (percent >= 0) out.push(limitWindow(entry.label, percent, entry.resetsAt, entry.title))",
    "      if (percent >= 0) {\n"
    "        var w = limitWindow(entry.label, percent, entry.resetsAt, entry.title)\n"
    "        w.sub = String(entry.sub || \"\")\n"
    "        w.plan = String(entry.plan || \"\")\n"
    "        out.push(w)\n"
    "      }",
    "limit subscription",
)
# One height for every tab: the tallest content the panel has shown this
# session, never less than the stock 640. Switching tabs then never moves the
# bottom edge (ruling 2026-10-03: no jumping between tabs).
patch(
    "    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(640))",
    "    contentHeight: panel.fittedContentHeight(\n"
    "      Math.max(Style.space(640), root.tallestContent, column.implicitHeight), Style.space(820))",
    "panel height",
)
patch(
    "  property bool cursorActive: false\n",
    "  property bool cursorActive: false\n"
    "  // The tallest tab so far: the panel keeps this height on every tab.\n"
    "  property real tallestContent: 0\n",
    "tallest property",
)
patch(
    "          id: column\n          width: panelFlick.width\n",
    "          id: column\n          width: panelFlick.width\n"
    "          onImplicitHeightChanged: root.tallestContent = Math.max(root.tallestContent, implicitHeight)\n",
    "tallest tracking",
)
# The subscription chips sit at the very top of every tab, above the hero the
# AI tab does not have, so a click on one never moves the row under the mouse.
switch_start = source.find("          // ---------- Provider switch ----------\n")
switch_end = source.find("          // ---------- Status ----------\n")
hero_start = source.find("          // ---------- Hero: provider mark")
if min(switch_start, switch_end, hero_start) < 0 or not hero_start < switch_start < switch_end:
    print("agents-panel-setup: patch anchor 'chips on top' missing; leaving that bit unpatched", file=sys.stderr)
else:
    block = source[switch_start:switch_end]
    source = source[:switch_start] + source[switch_end:]
    source = source[:hero_start] + block + source[hero_start:]
# The AI tab opens on one card per subscription (Claude, Google, Ollama), then
# tokens by day and by model over the same seven days, drawn on one grid
# (ruling 2026-10-03: subscription cards).
patch(
    "import QtQuick.Controls\n",
    "import QtQuick.Controls\nimport QtQuick.Layouts\n",
    "layouts import",
)
patch(
    "  readonly property var limits: limitWindows(provider)\n",
    "  readonly property var limits: limitWindows(provider)\n"
    "  readonly property var cards: modelsOnly ? quotaCards(providers) : []\n"
    "  // The AI tab's label column, shared by the day and model rows so their bars line up.\n"
    "  readonly property real modelNameWidth: Style.space(140)\n",
    "cards property",
)
patch(
    "  function resetMsFor(w) {\n",
    '''  // One card per subscription for the AI tab, in a fixed order: Claude, OpenAI,
  // Google, Ollama. A window names its subscription (`sub`) when its record runs
  // on more than one (opencode and pi run on Ollama and ChatGPT), and a
  // subscription two records share is read from the first. Google's windows
  // split into its two pools, Gemini and the partner models.
  function quotaCards(list) {
    var names = { "claude": "Claude", "agy": "Google", "opencode": "Ollama", "pi": "Ollama" }
    var order = ["Claude", "OpenAI", "Google", "Ollama"]
    function shortTitle(title) {
      var text = String(title || "").replace(/^(Gemini|Claude\\/GPT|OpenAI|Ollama)\\s+/, "")
      if (text === "Session") return "5h"
      if (text === "Weekly") return "week"
      if (text === "Monthly") return "month"
      return text.replace(/\\s*Weekly$/, "")
    }
    var cards = {}
    for (var i = 0; i < list.length; i++) {
      var p = list[i]
      var windows = limitWindows(p)
      var mine = {}
      for (var j = 0; j < windows.length; j++) {
        var w = windows[j]
        var name = w.sub || names[p.providerId] || p.providerName
        if (cards[name] && !mine[name]) continue
        if (!cards[name]) {
          cards[name] = { name: name, plan: w.plan || String(p.tierLabel || ""), groups: [] }
          mine[name] = true
        }
        var pool = name !== "Google" ? ""
          : (String(w.title).indexOf("Claude/GPT") === 0 ? "Claude · GPT" : "Gemini")
        var groups = cards[name].groups
        var group = null
        for (var k = 0; k < groups.length; k++) if (groups[k].title === pool) group = groups[k]
        if (!group) {
          group = { title: pool, windows: [] }
          groups.push(group)
        }
        group.windows.push({ title: shortTitle(w.title), used: clamp(w.percent, 0, 1), resetAt: w.resetAt })
      }
    }
    var out = []
    for (var n = 0; n < order.length; n++) if (cards[order[n]]) out.push(cards[order[n]])
    for (var key in cards) if (order.indexOf(key) < 0) out.push(cards[key])
    return out
  }

  function weekTotal(p) {
    var days = p ? (p.recentDays || []) : []
    var sum = 0
    for (var i = 0; i < days.length; i++) sum += Number(days[i].messageCount || 0)
    return sum
  }

  function resetMsFor(w) {
''',
    "quota cards",
)
patch(
    "          // ---------- Usage ----------\n",
    '''          // ---------- Subscription cards (AI tab) ----------
          PanelSeparator {
            visible: cardGrid.visible
            foreground: root.foreground
          }

          GridLayout {
            id: cardGrid
            visible: root.cards.length > 0
            width: parent.width
            columns: 2
            columnSpacing: Style.spacing.lg
            rowSpacing: Style.spacing.lg

            Repeater {
              model: root.cards

              QuotaCard {
                required property var modelData
                entry: modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
              }
            }
          }

          // ---------- Usage ----------
''',
    "cards section",
)
# The day chart on the AI tab: a seven-day total in the header, and the label
# column as wide as the model names so both charts share one grid.
patch(
    '''            PanelSectionHeader {
              width: parent.width
              text: "TOKENS BY DAY"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }
''',
    '''            Item {
              width: parent.width
              implicitHeight: dayHeader.implicitHeight

              PanelSectionHeader {
                id: dayHeader
                anchors.left: parent.left
                text: root.modelsOnly ? "TOKENS · 7 DAYS" : "TOKENS BY DAY"
                foreground: root.foreground
                fontFamily: root.fontFamily
              }

              PanelSectionHeader {
                visible: root.modelsOnly
                anchors.right: parent.right
                text: usage.formatTokenCount(root.weekTotal(root.provider))
                foreground: root.foreground
                fontFamily: root.fontFamily
              }
            }
''',
    "day header",
)
patch(
    "                day: modelData\n",
    "                day: modelData\n"
    "                labelWidth: root.modelsOnly ? root.modelNameWidth : Style.space(52)\n",
    "day label width",
)
patch(
    "    property bool today: false\n",
    "    property bool today: false\n    property real labelWidth: Style.space(52)\n",
    "day label property",
)
patch(
    '''      font.bold: dayRow.today
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(52)
''',
    '''      font.bold: dayRow.today
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: dayRow.labelWidth
''',
    "day label column",
)
# The model chart on the AI tab: thin bars like the days, the effort dimmed.
patch(
    '''            PanelSectionHeader {
              width: parent.width
              text: "TOKENS BY MODEL"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.models
''',
    '''            PanelSectionHeader {
              width: parent.width
              text: root.modelsOnly ? "MODELS · 7 DAYS" : "TOKENS BY MODEL"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Repeater {
              model: root.modelsOnly ? root.models : []

              ModelBarRow {
                required property var modelData
                width: modelSection.width
                row: modelData
                share: modelData.total / Math.max(1, root.models[0].total)
              }
            }

            Repeater {
              model: root.modelsOnly ? [] : root.models
''',
    "model rows",
)
patch(
    "  // Rounded track showing the percentage of the allowance used.\n",
    '''  // One subscription: its name and plan, then one line per window, grouped by
  // pool where a plan has two (Google: Gemini, and Claude and GPT).
  component QuotaCard: BorderSurface {
    id: card
    property var entry: null
    readonly property real pad: Style.space(10)

    radius: Style.cornerRadius
    color: root.alpha(root.foreground, 0.04)
    borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
    implicitHeight: cardColumn.implicitHeight + pad * 2

    Column {
      id: cardColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: card.pad
      spacing: Style.spacing.lg

      Item {
        width: parent.width
        implicitHeight: cardName.implicitHeight

        Text {
          id: cardName
          textFormat: Text.PlainText
          text: card.entry ? card.entry.name : ""
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          anchors.left: parent.left
        }

        Text {
          textFormat: Text.PlainText
          text: card.entry ? card.entry.plan : ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.right: parent.right
          anchors.baseline: cardName.baseline
        }
      }

      Repeater {
        model: card.entry ? card.entry.groups : []

        Column {
          id: groupColumn
          required property var modelData
          readonly property var group: modelData
          width: cardColumn.width
          spacing: Style.spacing.md

          Text {
            visible: groupColumn.group.title !== ""
            textFormat: Text.PlainText
            text: groupColumn.group.title
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Repeater {
            model: groupColumn.group.windows

            QuotaLine {
              required property var modelData
              width: groupColumn.width
              line: modelData
            }
          }
        }
      }
    }
  }

  // One window: label, a meter filling toward the cap, the share used, and the
  // time to its reset, in fixed columns so every card lines up.
  component QuotaLine: Item {
    id: quotaLine
    property var line: null
    readonly property bool alarming: !!line && line.used >= 0.9

    implicitHeight: Math.max(lineLabel.implicitHeight, lineUsed.implicitHeight)

    Text {
      id: lineLabel
      textFormat: Text.PlainText
      text: quotaLine.line ? quotaLine.line.title : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(40)
    }

    Meter {
      anchors.left: lineLabel.right
      anchors.right: lineUsed.left
      anchors.leftMargin: Style.space(6)
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      value: quotaLine.line ? quotaLine.line.used : -1
      alarming: quotaLine.alarming
    }

    Text {
      id: lineUsed
      textFormat: Text.PlainText
      text: quotaLine.line ? Math.round(quotaLine.line.used * 100) + "%" : ""
      color: quotaLine.alarming ? root.urgent : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      horizontalAlignment: Text.AlignRight
      anchors.right: lineReset.left
      anchors.rightMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(30)
    }

    Text {
      id: lineReset
      textFormat: Text.PlainText
      text: {
        var remainingMs = root.resetMsFor(quotaLine.line)
        return remainingMs > 0 ? root.formatDuration(remainingMs) : ""
      }
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignRight
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(40)
    }
  }

  // An AI-tab model row, drawn like a day row so both charts share one grid:
  // model (effort dimmed), a bar scaled to the heaviest model, tokens.
  component ModelBarRow: Item {
    id: barRow
    property var row: null
    property real share: 0
    readonly property var parts: {
      var name = String(row ? row.name : "")
      var match = name.match(/^(.*?) \\((.*)\\)$/)
      return match ? [match[1], match[2]] : [name, ""]
    }

    implicitHeight: Math.max(barName.implicitHeight, barValue.implicitHeight) + Style.spacing.sm

    Item {
      id: barLabel
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: root.modelNameWidth
      height: barName.implicitHeight

      Text {
        id: barName
        textFormat: Text.PlainText
        text: barRow.parts[0]
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        anchors.left: parent.left
        width: Math.min(implicitWidth, parent.width - barEffort.implicitWidth - barEffort.anchors.leftMargin)
      }

      Text {
        id: barEffort
        textFormat: Text.PlainText
        text: barRow.parts[1]
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        anchors.left: barName.right
        anchors.leftMargin: text !== "" ? Style.space(5) : 0
      }
    }

    Rectangle {
      anchors.left: barLabel.right
      anchors.right: barValue.left
      anchors.leftMargin: Style.space(8)
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      height: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))
      radius: height / 2
      color: root.track

      Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        radius: parent.radius
        width: parent.width * root.clamp(barRow.share, 0, 1)
        color: root.alpha(root.foreground, 0.55)

        Behavior on width {
          NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
      }
    }

    Text {
      id: barValue
      textFormat: Text.PlainText
      text: barRow.row ? usage.formatTokenCount(barRow.row.total) : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      horizontalAlignment: Text.AlignRight
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(52)
    }

    MouseArea {
      id: barHover
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
    }

    PanelToolTip {
      visible: barHover.containsMouse
      text: root.modelTooltip(barRow.row)
      fontFamily: root.fontFamily
    }
  }

  // Rounded track showing the percentage of the allowance used.
''',
    "card and model components",
)

path.write_text(source)
PY

install -m 0644 "$HERE"/agents-panel/*.svg "$CLONE/assets/"
# The Codex CLI tab (codex-cli) wears the stock Codex mark.
install -m 0644 "$STOCK/assets/codex.svg" "$CLONE/assets/codex-cli.svg"
install -m 0644 "$STOCK/assets/codex-light.svg" "$CLONE/assets/codex-cli-light.svg"

omarchy plugin enable "${USERNAME}.agents" >/dev/null 2>&1 || true
omarchy bar set "${USERNAME}.agents" providers \
  '{"claude":{"enabled":true},"codex":{"enabled":false},"fireworks":{"enabled":false}}' --json >/dev/null
