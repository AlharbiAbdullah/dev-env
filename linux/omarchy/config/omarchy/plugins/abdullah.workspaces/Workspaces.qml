import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// Mac-style workspace strip: "<focused> | <other occupied workspaces>".
// Only workspaces that hold windows are listed; the focused one always leads.
// The focused number sits in a filled accent capsule; the rest are bare and
// dimmed, so the current workspace reads at a glance the way the Mac dock does.
BarWidget {
  id: root
  moduleName: "abdullah.workspaces"

  function label(id) { return id === 10 ? "0" : String(id) }

  function entries() {
    var focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
    var others = []
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var ws = values[i]
      if (ws.id <= 0 || ws.id > 10 || ws.id === focusedId) continue
      var count = ws.toplevels ? ws.toplevels.values.length : 0
      if (count === 0 && ws.lastIpcObject) count = Number(ws.lastIpcObject.windows) || 0
      if (count > 0) others.push(ws.id)
    }
    others.sort(function(a, b) { return a - b })

    var out = []
    if (focusedId > 0) out.push({ kind: "ws", id: focusedId, focused: true })
    if (focusedId > 0 && others.length) out.push({ kind: "sep" })
    for (var j = 0; j < others.length; j++) out.push({ kind: "ws", id: others[j], focused: false })
    return out
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)
  // How far the box sits inside the bar island, so it never touches its edge.
  readonly property int boxInset: Math.max(2, Math.round(root.barSize * 0.16))
  // Every workspace gets the same square box. Only the fill tells them apart.
  readonly property int boxSize: Math.max(8, root.barSize - boxInset * 2)
  // Gap between neighbouring boxes, carried in the slot width.
  readonly property int boxGap: Style.space(5)
  readonly property int numberSlot: boxSize + boxGap
  // Square, to match the islands and Hyprland's decoration:rounding = 0.
  property int boxRadius: 0

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : Math.max(1, root.entries().length)
    columnSpacing: 0
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.entries()

      WidgetButton {
        id: wsButton
        required property var modelData

        readonly property bool isSep: modelData.kind === "sep"
        readonly property bool isFocused: !isSep && modelData.focused

        bar: root.bar
        text: isSep ? "|" : root.label(modelData.id)
        fontSize: Style.font.title
        // Dark text on the accent fill; the theme foreground everywhere else.
        readonly property color themeFg: root.bar ? root.bar.barForeground : Color.foreground
        foreground: isFocused
          ? Color.background
          : Qt.rgba(themeFg.r, themeFg.g, themeFg.b, 0.62)
        // WidgetButton does not expose weight; bolden its internal label.
        Component.onCompleted: {
          for (var i = 0; i < children.length; i++)
            if (children[i].font !== undefined) children[i].font.bold = !isSep
        }
        // Full opacity throughout; the dimming lives in the colors below so
        // the box does not fade along with its label.
        opacity: isSep ? 0.35 : 1
        interactive: !isSep
        pressable: !isSep
        horizontalMargin: isSep ? 2 : 4
        verticalPadding: 6
        fixedWidth: root.vertical
          ? root.barSize
          : (isSep ? Style.space(6) : root.numberSlot)
        fixedHeight: root.barSize
        onPressed: function() { if (!isSep) root.focusWorkspace(modelData.id) }

        HoverHandler { id: wsHover }

        // Behind the label: every workspace carries the same square box.
        // Solid accent marks the focused one; the rest get a dim lifted fill
        // that brightens on hover.
        Rectangle {
          z: -1
          anchors.centerIn: parent
          width: root.boxSize
          height: root.boxSize
          radius: root.boxRadius
          visible: !wsButton.isSep
          color: wsButton.isFocused
            ? Color.accent
            : Qt.rgba(wsButton.themeFg.r, wsButton.themeFg.g, wsButton.themeFg.b,
                      wsHover.hovered ? 0.20 : 0.10)

          Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
      }
    }
  }
}
