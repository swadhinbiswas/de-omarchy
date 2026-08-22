import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "deomarchy.power-profile"

  property string currentProfile: ""
  property var profiles: ["power-saver", "balanced", "performance"]
  property bool available: false

  visible: available
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!profileGetProc.running) profileGetProc.running = true
  }

  function profileIcon(name) {
    if (name === "performance") return "\uf0e7"
    if (name === "power-saver") return "\uf1e6"
    return "\uf110"
  }

  function profileLabel(name) {
    if (name === "performance") return "Performance"
    if (name === "power-saver") return "Powersave"
    return "Balanced"
  }

  function cycleProfile() {
    var idx = profiles.indexOf(currentProfile)
    var next = (idx + 1) % profiles.length
    setProfile(profiles[next])
  }

  function setProfile(name) {
    if (setProc.running) return
    setProc.command = ["powerprofilesctl", "set", name]
    setProc.running = true
  }

  Component.onCompleted: refresh()

  Process {
    id: profileGetProc
    command: ["powerprofilesctl", "get"]
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.available = false
        return
      }
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var profile = String(text || "").trim()
        if (profile !== "") {
          root.currentProfile = profile
          root.available = true
        }
      }
    }
  }

  Process {
    id: setProc
    stdout: StdioCollector { waitForEnd: true }
    onRunningChanged: {
      if (!running) root.refresh()
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    target: "deomarchy.power-profile"
    function refresh(): void { root.refresh() }
    function cycle(): void { root.cycleProfile() }
    function set(name: string): void { root.setProfile(name) }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.profileIcon(root.currentProfile)
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Power: " + root.profileLabel(root.currentProfile) + " (click to cycle)"
    onPressed: root.cycleProfile()
  }
}
