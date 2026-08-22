import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "deomarchy.plugin-library"

  property var plugins: []
  property int selectedIndex: -1
  property string statusText: ""
  property bool installing: false

  implicitWidth: 520
  implicitHeight: 600

  Component.onCompleted: loadRegistry()

  function loadRegistry() {
    var path = Quickshell.env("HOME") + "/.config/omarchy/plugins/registry.json"
    var fallback = (Quickshell.env("OMARCHY_PATH") || "/usr/share/de-omarchy") + "/registry.json"
    registryProc.command = ["bash", "-c", "cat " + path + " 2>/dev/null || cat " + fallback + " 2>/dev/null || echo '{\"plugins\":[]}'"]
    registryProc.running = true
  }

  Process {
    id: registryProc
    running: false
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var data = JSON.parse(String(line).trim())
          if (data && data.plugins) root.plugins = data.plugins
        } catch(e) {}
      }
    }
  }

  Process {
    id: installProc
    running: false
    onRunningChanged: {
      if (!running) {
        root.installing = false
        root.statusText = root.installExitCode === 0 ? "Installed!" : "Install failed"
        timer.restart()
      }
    }
    property int installExitCode: 0
    onExited: function(code) { installExitCode = code }
  }

  Timer {
    id: timer
    interval: 3000
    onTriggered: root.statusText = ""
  }

  function installPlugin(plugin) {
    if (root.installing) return
    root.installing = true
    root.statusText = "Installing " + plugin.name + "..."
    var pluginDir = Quickshell.env("HOME") + "/.config/omarchy/plugins"
    installProc.command = ["bash", "-c", "mkdir -p " + pluginDir + " && " + plugin.installCommand]
    installProc.running = true
  }

  Column {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    Row {
      width: parent.width
      spacing: 12

      Text {
        text: "Plugin Library"
        color: Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: 20
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
      }

      Item { width: 1; height: 1 }

      Rectangle {
        width: statusText.length > 0 ? statusLabel.implicitWidth + 20 : 0
        height: 24
        radius: 12
        color: installing ? Qt.rgba(0.2, 0.5, 0.9, 0.3) : Qt.rgba(0.2, 0.8, 0.3, 0.3)
        visible: statusText.length > 0
        anchors.verticalCenter: parent.verticalCenter

        Text {
          id: statusLabel
          anchors.centerIn: parent
          text: root.statusText
          color: Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: 11
        }
      }
    }

    Text {
      text: plugins.length + " plugins available"
      color: Color.subtext
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: 12
    }

    ListView {
      id: listView
      width: parent.width
      height: parent.height - 80
      clip: true
      spacing: 8
      model: root.plugins

      delegate: Rectangle {
        required property var modelData
        required property int index
        width: listView.width
        height: 90
        radius: 8
        color: index === root.selected ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.15) : Qt.rgba(1, 1, 1, 0.05)
        border.color: index === root.selected ? Color.accent : Qt.rgba(1, 1, 1, 0.1)
        border.width: index === root.selected ? 1 : 0

        Column {
          anchors.fill: parent
          anchors.margins: 10
          spacing: 4

          Row {
            width: parent.width
            spacing: 8

            Rectangle {
              width: 36; height: 36; radius: 8
              color: Qt.rgba(0.4, 0.5, 0.9, 0.2)
              Text {
                anchors.centerIn: parent
                text: modelData.name ? modelData.name.charAt(0) : "?"
                color: Color.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: 16
                font.bold: true
              }
            }

            Column {
              width: parent.width - 120
              spacing: 2

              Text {
                text: modelData.name || "Unknown"
                color: Color.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
              }

              Text {
                text: modelData.description || ""
                color: Color.subtext
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: 11
                elide: Text.ElideRight
                width: parent.width
              }

              Row {
                spacing: 6
                Text {
                  text: modelData.author || ""
                  color: Color.subtext
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: 10
                }
                Text {
                  text: (modelData.tags || []).join(", ")
                  color: Color.subtext
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: 10
                }
              }
            }

            Rectangle {
              width: 60; height: 28; radius: 6
              color: root.installing ? Qt.rgba(1,1,1,0.05) : Qt.rgba(0.3, 0.7, 0.3, 0.3)
              anchors.verticalCenter: parent.verticalCenter

              Text {
                anchors.centerIn: parent
                text: root.installing ? "..." : "Install"
                color: root.installing ? Color.subtext : Color.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: 11
                font.bold: true
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !root.installing
                onClicked: root.installPlugin(modelData)
              }
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: root.selectedIndex = index
        }
      }
    }
  }
}
