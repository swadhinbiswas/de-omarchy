import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "deomarchy.monitormgr"

  property var monitors: []
  property string wallpaperDir: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/backgrounds"
  property var wallpapers: []
  property int selectedMonitor: 0

  implicitWidth: 420
  implicitHeight: contentCol.implicitHeight + Style.spacing.controlPaddingX * 2

  Process {
    id: monitorQuery
    running: true
    command: ["hyprctl", "monitors", "-j"]
    stdout: SplitParser {
      onRead: function(line) {
        root.monitors = Model.parseMonitors(line)
      }
    }
  }

  Process {
    id: wpQuery
    running: true
    command: ["bash", "-c", "ls " + wallpaperDir + " 2>/dev/null || true"]
    stdout: SplitParser {
      onRead: function(line) {
        var t = String(line).trim()
        if (t && root.wallpapers.indexOf(t) === -1)
          root.wallpapers = root.wallpapers.concat([t])
      }
    }
  }

  Process {
    id: actionProc
    running: false
    onRunningChanged: if (!running) monitorQuery.running = true
  }

  function runAction(cmd) {
    actionProc.command = ["bash", "-c", cmd]
    actionProc.running = true
  }

  function rotateMonitor(name, cur) {
    runAction(Model.setMonitorRotation(name, (cur + 1) % 4))
  }

  function moveMonitor(name, dx, dy, x, y) {
    runAction(Model.setMonitorPosition(name, x + dx, y + dy))
  }

  Column {
    id: contentCol
    anchors.fill: parent
    anchors.margins: Style.spacing.controlPaddingX
    spacing: 8

    Text {
      text: "Monitors"
      color: Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.heading
      font.bold: true
      opacity: 0.9
    }

    Repeater {
      model: root.monitors
      delegate: Rectangle {
        required property var modelData
        property var mon: modelData
        width: contentCol.width
        height: monCol.implicitHeight + 16
        radius: 8
        color: mon.focused ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15)
                           : Qt.rgba(1, 1, 1, 0.05)
        border.color: mon.focused ? Color.accent : Qt.rgba(1, 1, 1, 0.1)
        border.width: mon.focused ? 1 : 0

        Column {
          id: monCol
          anchors.fill: parent
          anchors.margins: 8
          spacing: 6

          Text {
            text: mon.name + (mon.focused ? " (focused)" : "") + "  " + mon.description
            color: Color.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            text: mon.width + "x" + mon.height + " @ " + mon.refreshRate + "Hz   " + mon.rotation + "\u00b0   Scale: " + mon.scale
            color: Color.subtext
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.small
          }

          Text {
            text: "Position: " + mon.x + " x " + mon.y
            color: Color.subtext
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.small
          }

          Row {
            spacing: 6

            Repeater {
              model: [
                { label: "\u2190", action: function() { root.moveMonitor(mon.name, -1920, 0, mon.x, mon.y) } },
                { label: "\u2192", action: function() { root.moveMonitor(mon.name, 1920, 0, mon.x, mon.y) } },
                { label: "\u2191", action: function() { root.moveMonitor(mon.name, 0, -1080, mon.x, mon.y) } },
                { label: "\u2193", action: function() { root.moveMonitor(mon.name, 0, 1080, mon.x, mon.y) } },
                { label: "\u21bb", action: function() { root.rotateMonitor(mon.name, mon.transform) } }
              ]
              delegate: Rectangle {
                width: 36; height: 28; radius: 4
                color: moveArea.containsMouse ? Qt.rgba(1,1,1,0.2) : Qt.rgba(1,1,1,0.08)
                Text {
                  anchors.centerIn: parent
                  text: modelData.label
                  color: Color.foreground
                  font.pixelSize: 14
                }
                MouseArea {
                  id: moveArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: modelData.action()
                }
              }
            }
          }
        }
      }
    }
  }
}
