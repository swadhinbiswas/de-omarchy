import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property var wallpapers: []
  property int selectedIndex: -1
  property string wallpaperDir: ""
  property bool cursorActive: false

  function open(payloadJson) {
    opened = true
    selectedIndex = -1
    cursorActive = false
    loadWallpapers()
  }

  function close() {
    opened = false
    wallpapers = []
    selectedIndex = -1
  }

  function dismiss() {
    if (shell && typeof shell.hide === "function")
      shell.hide((manifest && manifest.id) || "deomarchy.wallpaper-manager")
    else close()
  }

  function loadWallpapers() {
    if (dirProc.running) return
    dirProc.running = true
  }

  function updateDirList(raw) {
    var dir = String(raw || "").trim()
    if (dir === "") {
      wallpaperDir = ""
      wallpapers = []
      return
    }
    wallpaperDir = dir
    if (!listProc.running) listProc.running = true
  }

  function updateFileList(raw) {
    var lines = String(raw || "").trim().split("\n")
    var files = []
    for (var i = 0; i < lines.length; i++) {
      var f = lines[i].trim()
      if (f !== "" && (f.endsWith(".png") || f.endsWith(".jpg") || f.endsWith(".jpeg") || f.endsWith(".webp")))
        files.push(f)
    }
    wallpapers = files
  }

  function selectByDelta(delta) {
    if (wallpapers.length === 0) return
    if (selectedIndex < 0) selectedIndex = delta > 0 ? 0 : wallpapers.length - 1
    else selectedIndex = Math.max(0, Math.min(wallpapers.length - 1, selectedIndex + delta))
  }

  function applyWallpaper() {
    if (selectedIndex < 0 || selectedIndex >= wallpapers.length || wallpaperDir === "") return
    var path = wallpaperDir + "/" + wallpapers[selectedIndex]
    applyProc.command = ["omarchy-theme-bg-set", path]
    applyProc.running = true
  }

  Process {
    id: dirProc
    command: ["bash", "-c", "echo $OMARCHY_PATH/default/themed/backgrounds || echo ~/.local/state/omarchy/current/theme/backgrounds"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateDirList(text)
    }
  }

  Process {
    id: listProc
    command: ["ls", wallpaperDir]
    onExited: function(exitCode) {
      if (exitCode !== 0) root.wallpapers = []
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateFileList(text)
    }
  }

  Process {
    id: applyProc
    stdout: StdioCollector { waitForEnd: true }
    onRunningChanged: {
      if (!running) root.close()
    }
  }

  PanelController {
    id: controller
    open: root.opened
    onOpenChanged: {
      if (!open) root.close()
    }

    Rectangle {
      id: panelBg
      anchors.fill: parent
      color: Color.background
      radius: Style.radius.l

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(16)
        spacing: Style.space(12)

        RowLayout {
          Layout.fillWidth: true

          Text {
            text: "Wallpapers"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            Layout.fillWidth: true
          }

          Button {
            text: "Close"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            onClicked: root.dismiss()
          }
        }

        Text {
          visible: wallpapers.length === 0
          text: root.wallpaperDir === "" ? "No wallpaper directory found" : "No wallpapers found"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          opacity: 0.6
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          Layout.topMargin: Style.space(40)
        }

        ScrollView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

          GridView {
            id: grid
            cellWidth: (width - Style.space(8)) / 3
            cellHeight: cellWidth * 0.6 + Style.space(28)
            model: wallpapers

            delegate: Rectangle {
              required property string modelData
              required property int index
              width: grid.cellWidth
              height: grid.cellHeight
              color: root.selectedIndex === index ? Color.accent : "transparent"
              radius: Style.radius.s

              Column {
                anchors.fill: parent
                anchors.margins: Style.space(4)
                spacing: Style.space(4)

                Rectangle {
                  width: parent.width
                  height: parent.height - nameText.implicitHeight - Style.space(8)
                  color: Qt.darker(Color.foreground, 3.0)
                  radius: Style.radius.s
                  clip: true

                  Image {
                    anchors.fill: parent
                    anchors.margins: Style.space(2)
                    source: root.wallpaperDir + "/" + modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                  }
                }

                Text {
                  id: nameText
                  width: parent.width
                  text: modelData
                  color: Color.foreground
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  horizontalAlignment: Text.AlignHCenter
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.selectedIndex = index
                  root.applyWallpaper()
                }
                onContainsMouseChanged: {
                  if (containsMouse) {
                    root.cursorActive = true
                    root.selectedIndex = index
                  }
                }
              }
            }
          }
        }

        Text {
          visible: wallpapers.length > 0
          text: "Click to set wallpaper"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          opacity: 0.5
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
