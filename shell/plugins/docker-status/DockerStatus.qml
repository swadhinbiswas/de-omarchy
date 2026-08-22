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

  visible: dockerAvailable
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!dockerProc.running) dockerProc.running = true
  }

  function updateStatus(raw) {
    var lines = String(raw || "").trim().split("\n")
    var running = 0
    var unhealthy = 0
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line === "") continue
      var parts = line.split("|")
      if (parts.length < 2) continue
      var status = parts[1].toLowerCase()
      if (status.indexOf("up") !== -1) {
        running++
        if (status.indexOf("unhealthy") !== -1) unhealthy++
      }
    }
    runningCount = running
    unhealthyCount = unhealthy
    dockerAvailable = true
  }

  function statusText() {
    if (unhealthyCount > 0)
      return runningCount + " up, " + unhealthyCount + " unhealthy"
    return runningCount + " running"
  }

  Component.onCompleted: refresh()

  Process {
    id: dockerProc
    command: ["docker", "ps", "--format", "{{.Names}}|{{.Status}}"]
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        dockerAvailable = false
        return
      }
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

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf308"
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Docker: " + root.statusText()
    onPressed: root.refresh()
  }
}
