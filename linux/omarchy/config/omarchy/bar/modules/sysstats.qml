import QtQuick
import Quickshell
import Quickshell.Io

// CPU / RAM / GPU usage as plain text. Reads /proc and amdgpu sysfs directly,
// no helper process per tick. Left click opens btop.
Item {
  id: root

  property var bar
  property string moduleName
  property var settings

  property int cpu: 0
  property int ram: 0
  property int gpu: 0
  property real ramUsedGb: 0
  property real ramTotalGb: 0
  property real vramUsedGb: 0
  property real vramTotalGb: 0

  property real prevIdle: 0
  property real prevTotal: 0
  property string gpuDir: ""

  implicitWidth: label.implicitWidth + 12
  implicitHeight: bar ? bar.barSize : 26

  function readCpu(text) {
    var f = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
    var idle = f[3] + f[4]
    var total = f.reduce(function(a, b) { return a + b }, 0)
    var dt = total - prevTotal
    if (prevTotal > 0 && dt > 0) cpu = Math.round(100 * (1 - (idle - prevIdle) / dt))
    prevIdle = idle
    prevTotal = total
  }

  function readMem(text) {
    var m = {}
    text.split("\n").forEach(function(line) {
      var p = line.split(/:\s+/)
      if (p.length === 2) m[p[0]] = parseInt(p[1])
    })
    if (!m.MemTotal) return
    ramTotalGb = m.MemTotal / 1048576
    ramUsedGb = (m.MemTotal - m.MemAvailable) / 1048576
    ram = Math.round(100 * (m.MemTotal - m.MemAvailable) / m.MemTotal)
  }

  FileView { id: statFile; path: "/proc/stat"; blockLoading: true; printErrors: false }
  FileView { id: memFile; path: "/proc/meminfo"; blockLoading: true; printErrors: false }
  FileView { id: gpuBusy; path: root.gpuDir ? root.gpuDir + "/gpu_busy_percent" : ""; blockLoading: true; printErrors: false }
  FileView { id: vramUsed; path: root.gpuDir ? root.gpuDir + "/mem_info_vram_used" : ""; blockLoading: true; printErrors: false }
  FileView { id: vramTotal; path: root.gpuDir ? root.gpuDir + "/mem_info_vram_total" : ""; blockLoading: true; printErrors: false }

  // The amdgpu card index (card0/card1) can change between boots, so find it once.
  Process {
    running: true
    command: ["sh", "-c", "for f in /sys/class/drm/card*/device/gpu_busy_percent; do [ -r \"$f\" ] && dirname \"$f\" && break; done"]
    stdout: StdioCollector { onStreamFinished: root.gpuDir = text.trim() }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statFile.reload(); root.readCpu(statFile.text())
      memFile.reload(); root.readMem(memFile.text())
      if (root.gpuDir) {
        gpuBusy.reload(); root.gpu = parseInt(gpuBusy.text()) || 0
        vramUsed.reload(); vramTotal.reload()
        root.vramUsedGb = (parseInt(vramUsed.text()) || 0) / 1073741824
        root.vramTotalGb = (parseInt(vramTotal.text()) || 0) / 1073741824
      }
    }
  }

  readonly property color fg: bar ? bar.foreground : "white"
  readonly property string family: bar ? bar.fontFamily : "monospace"

  // Reserve room for "00%" so single/double-digit changes never shift the row.
  TextMetrics { id: valueSlot; font.family: root.family; font.pixelSize: 12; text: "00%" }

  Row {
    id: label
    anchors.centerIn: parent
    spacing: 12

    Repeater {
      model: [["CPU", root.cpu], ["RAM", root.ram], ["GPU", root.gpu]]

      Row {
        required property var modelData
        spacing: 5

        Text {
          text: modelData[0]
          color: root.fg
          opacity: 0.55
          font.family: root.family
          font.pixelSize: 12
        }
        Text {
          width: Math.max(valueSlot.advanceWidth, implicitWidth)
          text: modelData[1] + "%"
          color: root.fg
          font.family: root.family
          font.pixelSize: 12
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
    onEntered: if (root.bar) root.bar.showTooltip(root,
      "RAM " + root.ramUsedGb.toFixed(1) + " / " + root.ramTotalGb.toFixed(1) + " GB\n" +
      "VRAM " + root.vramUsedGb.toFixed(1) + " / " + root.vramTotalGb.toFixed(1) + " GB")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}
