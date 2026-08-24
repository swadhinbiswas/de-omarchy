import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.sysmon"

  property int cpuPct: 0
  property int memPct: 0
  property int diskPct: 0
  property int gpuTemp: 0
  property int cpuTemp: 0
  property string netDown: "0.0"
  property string netUp: "0.0"
  property bool sampled: false

  // Poll interval in ms. The sampler itself needs ~0.6s inside each tick to
  // measure its delta window, so don't push this below ~1500.
  readonly property int intervalMs: setting("intervalMs", 2000)

  readonly property string scriptPath: Qt.resolvedUrl("sysmon-stats.sh").toString().replace("file://", "")

  visible: !root.vertical && sampled
  implicitWidth: row.implicitWidth + Style.spacing.controlPaddingX * 2
  implicitHeight: barSize

  function refresh() {
    if (!statsProc.running) statsProc.running = true
  }

  function applyStats(line) {
    var m = String(line).match(/C=(\d+) M=(\d+) D=(\d+) G=(\d+) T=(-?\d+) RX=([\d.]+) TX=([\d.]+)/)
    if (!m) return
    root.cpuPct = parseInt(m[1])
    root.memPct = parseInt(m[2])
    root.diskPct = parseInt(m[3])
    root.gpuTemp = parseInt(m[4])
    root.cpuTemp = parseInt(m[5])
    root.netDown = m[6]
    root.netUp = m[7]
    root.sampled = true
  }

  Component.onCompleted: refresh()

  Process {
    id: statsProc
    command: ["bash", root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStats(text)
    }
  }

  Timer {
    interval: root.intervalMs
    running: true
    repeat: true
    onTriggered: root.broadcast("refresh")
  }

  IpcHandler {
    target: "omarchy.sysmon"
    function refresh(): void { root.broadcast("refresh") }
  }

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: 10

    Repeater {
      model: [
        { icon: "", value: root.cpuPct + "%" },
        { icon: "󱋗", value: root.cpuTemp + "°" },
        { icon: "󰗻", value: root.memPct + "%" },
        { icon: "󰋓", value: root.diskPct + "%" },
        { icon: "󱈘", value: root.gpuTemp + "°" },
        { icon: "󰇣", value: root.netDown + "↓" },
        { icon: "\uf093", value: root.netUp + "↑" }
      ]
      delegate: Text {
        text: modelData.icon + " " + modelData.value
        color: root.bar ? root.bar.barForeground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        opacity: 0.85
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.bar.run("uwsm-app -- kitty -e btop")
    }
    onEntered: {
      if (root.bar) root.bar.showTooltip(root,
        "CPU " + root.cpuPct + "% @ " + root.cpuTemp + "°\n" +
        "RAM " + root.memPct + "%\n" +
        "Disk " + root.diskPct + "%\n" +
        "GPU " + root.gpuTemp + "°\n" +
        "Net ↓ " + root.netDown + " MB/s  ↑ " + root.netUp + " MB/s\n" +
        "Click for btop")
    }
  }
}
