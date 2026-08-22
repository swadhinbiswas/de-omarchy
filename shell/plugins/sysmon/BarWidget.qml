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
  property string netDown: "0"
  property string netUp: "0"

  readonly property string scriptPath: omarchyPath + "/shell/plugins/sysmon/sysmon-stats.sh"

  Process {
    id: proc
    running: true
    command: ["bash", scriptPath]
    stdout: SplitParser {
      onRead: function(line) {
        var m = String(line).match(/C=(\d+) M=(\d+) D=(\d+) G=(\d+) T=(\d+) RX=([\d.]+) TX=([\d.]+)/)
        if (m) {
          root.cpuPct = parseInt(m[1])
          root.memPct = parseInt(m[2])
          root.diskPct = parseInt(m[3])
          root.gpuTemp = parseInt(m[4])
          root.cpuTemp = parseInt(m[5])
          root.netDown = m[6]
          root.netUp = m[7]
        }
      }
    }
  }

  implicitWidth: row.implicitWidth + Style.spacing.controlPaddingX * 2
  implicitHeight: barSize
  visible: !root.vertical

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: 10

    Repeater {
      model: [
        { icon: "", value: root.cpuPct + "%" },
        { icon: "󱋗", value: root.cpuTemp + "\u00b0" },
        { icon: "󰗻", value: root.memPct + "%" },
        { icon: "󰋓", value: root.diskPct + "%" },
        { icon: "󱈘", value: root.gpuTemp + "\u00b0" },
        { icon: "󰇣", value: root.netDown + "\u2193" },
        { icon: "", value: root.netUp + "\u2191" }
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
}
