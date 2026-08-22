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

  implicitWidth: label.implicitWidth + Style.spacing.controlPaddingX * 2
  implicitHeight: barSize
  visible: !root.vertical

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    text: "" + root.cpuPct + "% " + root.cpuTemp + "\u00b0  󰗻" + root.memPct + "%  󰋓" + root.diskPct + "%  󱋗" + root.gpuTemp + "\u00b0  󰇣" + root.netDown + "\u2193 " + root.netUp + "\u2191"
    color: root.bar ? root.bar.barForeground : Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    opacity: 0.85
  }
}
