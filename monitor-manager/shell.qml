import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root

  property var monitors: []
  property int selected: -1

  function selMon() { return selected >= 0 ? monitors[selected] : null }

  function applyMon(m) {
    var t = m.transform || 0
    var cmd = "hl.monitor({output=\"" + m.name + "\", mode=\"preferred\", position=\"" + m.x + "x" + m.y + "\", scale=" + m.scale + ", transform=" + t + "})"
    applyProc.command = ["hyprctl", "eval", cmd]
    applyProc.running = true
  }

  Process {
    id: queryProc
    running: true
    command: ["bash", "-c", "hyprctl monitors -j | tr -d \"\\n\""]
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var arr = JSON.parse(String(line).trim())
          if (Array.isArray(arr)) root.monitors = arr
        } catch(e) {}
      }
    }
  }

  Process {
    id: applyProc
    running: false
    onRunningChanged: if (!running) queryProc.running = true
  }

  function mapBounds() {
    var minX=0, minY=0, maxX=1, maxY=1
    for (var i = 0; i < monitors.length; i++) {
      var m = monitors[i]
      var w = (m.transform % 2 === 1) ? m.height : m.width
      var h = (m.transform % 2 === 1) ? m.width : m.height
      if (m.x < minX) minX = m.x
      if (m.y < minY) minY = m.y
      if (m.x + w > maxX) maxX = m.x + w
      if (m.y + h > maxY) maxY = m.y + h
    }
    return { minX: minX, minY: minY, w: Math.max(1, maxX - minX), h: Math.max(1, maxY - minY) }
  }

  Window {
    id: win
    title: "Monitor Manager"
    visible: true
    width: 780
    height: 520
    color: "#1a1b26"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      Text { text: "Display Arrangement"; color: "#c0caf5"; font.pixelSize: 20; font.bold: true }

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          color: "#16161e"
          radius: 10
          border.color: "#33467c"; border.width: 1

          Repeater {
            model: root.monitors

            Rectangle {
              required property var modelData
              required property int index
              property var b: root.mapBounds()
              property bool landscape: (modelData.transform % 2) === 0

              x: (modelData.x - b.minX) / b.w * (parent.width - 40) + 20
              y: (modelData.y - b.minY) / b.h * (parent.height - 40) + 20
              width: Math.max(60, (landscape ? modelData.width : modelData.height) / b.w * (parent.width - 60))
              height: Math.max(45, (landscape ? modelData.height : modelData.width) / b.h * (parent.height - 60))
              radius: 8
              color: index === root.selected ? "#3d59a188" : "#24283b"
              border.color: index === root.selected ? "#7aa2f7" : "#414868"
              border.width: index === root.selected ? 2 : 1

              Column {
                anchors.centerIn: parent
                spacing: 2
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: "#c0caf5"; font.bold: true; font.pixelSize: 13 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.width + "x" + modelData.height; color: "#9aa5ce"; font.pixelSize: 11 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: [ "0 deg","90 deg","180 deg","270 deg" ][modelData.transform % 4]; color: "#bb9af7"; font.pixelSize: 11 }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: root.selected = index
                drag.target: parent
                drag.axis: Drag.XAndYAxis
                onReleased: {
                  var b = root.mapBounds()
                  var nx = Math.round((parent.x - 20) / (parent.parent.width - 60) * b.w + b.minX)
                  var ny = Math.round((parent.y - 20) / (parent.parent.height - 60) * b.h + b.minY)
                  var m = JSON.parse(JSON.stringify(root.monitors[index]))
                  m.x = nx; m.y = ny
                  var arr = root.monitors.slice(); arr[index] = m
                  root.monitors = arr
                  root.applyMon(m)
                }
              }
            }
          }

          Text { visible: root.monitors.length === 0; anchors.centerIn: parent; text: "No monitors detected"; color: "#565f89" }
        }

        Rectangle {
          Layout.preferredWidth: 260
          Layout.fillHeight: true
          color: "#16161e"
          radius: 10
          border.color: "#33467c"; border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Text { text: root.selMon() ? root.selMon().name : "Select a display"; color: "#7aa2f7"; font.bold: true; font.pixelSize: 15 }

            GridLayout {
              columns: 3
              Layout.alignment: Qt.AlignHCenter
              Repeater {
                model: [
                  { l: "\u2190", dx: -1920, dy: 0 }, { l: "\u2191", dx: 0, dy: -1080 }, { l: "\u2192", dx: 1920, dy: 0 },
                  { l: "\u21bb", rot: true }, "", { l: "\u2193", dx: 0, dy: 1080 }
                ]
                delegate: Button {
                  visible: modelData !== ""
                  text: modelData.l || ""
                  width: 56; height: 34
                  onClicked: {
                    var m = JSON.parse(JSON.stringify(root.monitors[root.selected]))
                    if (modelData.rot) m.transform = ((m.transform || 0) + 1) % 4
                    else { m.x += modelData.dx; m.y += modelData.dy }
                    var arr = root.monitors.slice(); arr[root.selected] = m
                    root.monitors = arr
                    root.applyMon(m)
                  }
                }
              }
            }

            Text { text: "Scale"; color: "#9aa5ce"; font.pixelSize: 12 }

            ComboBox {
              Layout.fillWidth: true
              model: ["0.75", "1", "1.25", "1.5", "1.6", "2"]
              onActivated: {
                if (root.selected < 0) return
                var m = JSON.parse(JSON.stringify(root.monitors[root.selected]))
                m.scale = parseFloat(currentText)
                var arr = root.monitors.slice(); arr[root.selected] = m
                root.monitors = arr
                root.applyMon(m)
              }
            }

            Item { Layout.fillHeight: true }

            Text {
              visible: root.selMon() !== null
              text: root.selMon() ? ("pos: " + root.selMon().x + " x " + root.selMon().y + "\nscale: " + root.selMon().scale) : ""
              color: "#565f89"; font.pixelSize: 11
            }
          }
        }
      }

      Text { text: "Drag displays to arrange \u00b7 click a display then use arrows to nudge \u00b7 \u21bb rotates 90 deg"; color: "#565f89"; font.pixelSize: 11 }
    }
  }
}
