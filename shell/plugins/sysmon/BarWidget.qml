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
  property string netDown: "0"
  property string netUp: "0"

  readonly property string scriptPath: omarchyPath + "/shell/plugins/sysmon/sysmon-stats.sh"

  Process {
    id: proc
    running: true
    command: ["bash", scriptPath]
    stdout: SplitParser {
      onUpdate: function() {
        var m = proc.stdout.match(/C=(\d+) M=(\d+) D=(\d+) G=(\d+) RX=([\d.]+) TX=([\d.]+)/)
        if (m) {
          root.cpuPct = parseInt(m[1])
          root.memPct = parseInt(m[2])
          root.diskPct = parseInt(m[3])
          root.gpuTemp = parseInt(m[4])
          root.netDown = m[5]
          root.netUp = m[6]
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
    spacing: Style.spacing.gap

    Text { text: "󰻠" + root.cpuPct + "%"; color: Color.foreground; font.family: bar.fontFamily; font.pixelSize: Style.font.body; opacity: 0.85 }
    Text { text: "󰍛" + root.memPct + "%"; color: Color.foreground; font.family: bar.fontFamily; font.pixelSize: Style.font.body; opacity: 0.85 }
    Text { text: "󰋊" + root.diskPct + "%"; color: Color.foreground; font.family: bar.fontFamily; font.pixelSize: Style.font.body; opacity: 0.85 }
    Text { text: "󱋗" + root.gpuTemp + "°"; color: Color.foreground; font.family: bar.fontFamily; font.pixelSize: Style.font.body; opacity: 0.85 }
    Text { text: "󰈯" + root.netDown + "↓ " + root.netUp + "↑"; color: Color.foreground; font.family: bar.fontFamily; font.pixelSize: Style.font.body; opacity: 0.85 }
  }
}
