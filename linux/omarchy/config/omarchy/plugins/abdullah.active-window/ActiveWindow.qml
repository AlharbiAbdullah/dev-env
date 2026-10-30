import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "window-details.js" as WindowDetails

BarWidget {
  id: root
  moduleName: "abdullah.active-window"

  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property string title: toplevel
    ? WindowDetails.format(toplevel.appId, toplevel.title).text : ""
  readonly property int maxLabelWidth: Number(setting("maxWidth", 480))

  visible: title !== "" && !vertical
  implicitWidth: visible
    ? separator.implicitWidth + Style.space(24)
      + Math.min(maxLabelWidth, labelText.implicitWidth) : 0
  implicitHeight: barSize

  Behavior on implicitWidth {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }

  Item {
    anchors.fill: parent
    anchors.leftMargin: Style.space(8)
    anchors.rightMargin: Style.space(8)
    clip: true

    Text {
      id: separator
      text: "|"
      anchors.verticalCenter: parent.verticalCenter
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      opacity: 0.65
    }

    Text {
      id: labelText
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: separator.right
      anchors.leftMargin: Style.space(8)
      anchors.right: parent.right
      text: root.title
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
      opacity: 0.85
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function(mouse) {
      if (!root.toplevel) return
      if (mouse.button === Qt.MiddleButton) {
        root.toplevel.close()
      } else if (mouse.button === Qt.RightButton) {
        root.toplevel.close()
      } else {
        root.toplevel.activate()
      }
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.title)
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}
