import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "deomarchy.docker-status"

  property int runningCount: 0
  property int unhealthyCount: 0
  property bool dockerAvailable: false
  property string containerList: ""

  visible: dockerAvailable
  implicitWidth: label.implicitWidth + Style.spacing.controlPaddingX * 2
  implicitHeight: barSize

  function refresh() {
    if (!dockerProc.running) dockerProc.running = true
  }

  function updateStatus(raw) {
    var lines = String(raw || "").trim().split("\n")
    var running = 0
    var unhealthy = 0
    var names = []
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line === "") continue
      var parts = line.split("|")
      if (parts.length < 2) continue
      var status = parts[1].toLowerCase()
      if (status.indexOf("up") !== -1) {
        running++
        names.push(parts[0])
        if (status.indexOf("unhealthy") !== -1) unhealthy++
      }
    }
    runningCount = running
    unhealthyCount = unhealthy
    containerList = names.join(", ")
    dockerAvailable = running > 0 || unhealthy > 0
  }

  Component.onCompleted: refresh()

  Process {
    id: dockerProc
    command: ["docker", "ps", "--format", "{{.Names}}|{{.Status}}"]
    onExited: function(exitCode) {
      if (exitCode !== 0) root.dockerAvailable = false
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateStatus(text)
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "deomarchy.docker-status"
    function refresh(): void { root.refresh() }
  }

  Text {
    id: label
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.unhealthyCount > 0
      ? "\uf308 " + root.runningCount + " \u26a0"
      : "\uf308 " + root.runningCount
    color: root.unhealthyCount > 0 ? Color.urgent : Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    opacity: 0.85
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.refresh()
    onEntered: {
      if (root.bar) root.bar.showTooltip(root, "Docker: " + root.runningCount + " running\n" + root.containerList)
    }
  }
}
