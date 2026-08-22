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

  property string cpuUsage: "--"
  property string memUsage: "--"
  property string memTotal: "--"
  property string diskUsage: "--"
  property string gpuTemp: "--"
  property string netRx: "--"
  property string netTx: "--"
  property string uptime: "--"
  property string kernel: "--"
  property string hostname: "--"
  property string cpuModel: "--"
  property real prevCpuIdle: 0
  property real prevCpuTotal: 0

  function open(payloadJson) {
    opened = true
    refresh()
  }

  function close() {
    opened = false
  }

  function dismiss() {
    if (shell && typeof shell.hide === "function")
      shell.hide((manifest && manifest.id) || "deomarchy.system-overview")
    else close()
  }

  function refresh() {
    if (!cpuProc.running) cpuProc.running = true
    if (!memProc.running) memProc.running = true
    if (!diskProc.running) diskProc.running = true
    if (!tempProc.running) tempProc.running = true
    if (!netProc.running) netProc.running = true
    if (!uptimeProc.running) uptimeProc.running = true
    if (!infoProc.running) infoProc.running = true
  }

  function parseCpuLine(raw) {
    var line = String(raw || "").trim()
    var parts = line.split(/\s+/)
    if (parts.length < 5) return
    var idle = parseFloat(parts[3]) || 0
    var total = 0
    for (var i = 1; i < parts.length; i++) total += parseFloat(parts[i]) || 0
    if (prevCpuTotal > 0) {
      var dTotal = total - prevCpuTotal
      var dIdle = idle - prevCpuIdle
      if (dTotal > 0) cpuUsage = Math.round((1 - dIdle / dTotal) * 100) + "%"
    }
    prevCpuIdle = idle
    prevCpuTotal = total
  }

  function parseMem(raw) {
    var lines = String(raw || "").trim().split("\n")
    var total = 0
    var avail = 0
    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].trim().split(/\s+/)
      if (parts[0] === "MemTotal:") total = parseFloat(parts[1]) || 0
      if (parts[0] === "MemAvailable:") avail = parseFloat(parts[1]) || 0
    }
    if (total > 0) {
      memTotal = (total / 1048576).toFixed(1) + " GB"
      var used = total - avail
      memUsage = Math.round(used / total * 100) + "%"
    }
  }

  function parseDisk(raw) {
    var line = String(raw || "").trim()
    var parts = line.split(/\s+/)
    if (parts.length >= 5) diskUsage = parts[4] || "--"
  }

  function parseTemp(raw) {
    var line = String(raw || "").trim()
    var temp = parseFloat(line)
    if (isFinite(temp)) gpuTemp = Math.round(temp / 1000) + "\u00b0C"
    else gpuTemp = "--"
  }

  function parseNet(raw) {
    var lines = String(raw || "").trim().split("\n")
    var totalRx = 0
    var totalTx = 0
    for (var i = 1; i < lines.length; i++) {
      var parts = lines[i].trim().split(/[\s:]+/)
      if (parts.length < 10) continue
      var iface = parts[0]
      if (iface === "lo" || iface === "") continue
      totalRx += parseFloat(parts[1]) || 0
      totalTx += parseFloat(parts[9]) || 0
    }
    netRx = formatBytes(totalRx)
    netTx = formatBytes(totalTx)
  }

  function parseUptime(raw) {
    var sec = parseFloat(String(raw || "").trim())
    if (!isFinite(sec) || sec < 0) { uptime = "--"; return }
    var d = Math.floor(sec / 86400)
    var h = Math.floor((sec % 86400) / 3600)
    var m = Math.floor((sec % 3600) / 60)
    var parts = []
    if (d > 0) parts.push(d + "d")
    if (h > 0) parts.push(h + "h")
    parts.push(m + "m")
    uptime = parts.join(" ")
  }

  function parseInfo(raw) {
    var lines = String(raw || "").trim().split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line.indexOf("hostname") === 0) hostname = line.split("=", 2)[1] || "--"
      if (line.indexOf("kernel") === 0) kernel = line.split("=", 2)[1] || "--"
      if (line.indexOf("model name") === 0) cpuModel = line.split(":", 2)[1] || "--"
    }
  }

  function formatBytes(b) {
    if (b < 1024) return Math.round(b) + " B"
    if (b < 1048576) return (b / 1024).toFixed(1) + " KB"
    if (b < 1073741824) return (b / 1048576).toFixed(1) + " MB"
    return (b / 1073741824).toFixed(2) + " GB"
  }

  Component.onCompleted: {
    refresh()
    kernelProc.running = true
  }

  Process {
    id: cpuProc
    command: ["bash", "-c", "head -1 /proc/stat"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseCpuLine(text)
    }
  }

  Process {
    id: memProc
    command: ["bash", "-c", "head -2 /proc/meminfo"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseMem(text)
    }
  }

  Process {
    id: diskProc
    command: ["bash", "-c", "df -h / | tail -1"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseDisk(text)
    }
  }

  Process {
    id: tempProc
    command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo ''"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseTemp(text)
    }
  }

  Process {
    id: netProc
    command: ["bash", "-c", "head -5 /proc/net/dev"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseNet(text)
    }
  }

  Process {
    id: uptimeProc
    command: ["bash", "-c", "cut -d. -f1 /proc/uptime"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseUptime(text)
    }
  }

  Process {
    id: kernelProc
    command: ["bash", "-c", "echo hostname=$(hostname) && echo kernel=$(uname -r) && grep 'model name' /proc/cpuinfo | head -1"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseInfo(text)
    }
  }

  Process {
    id: infoProc
    command: ["bash", "-c", "echo hostname=$(hostname) && echo kernel=$(uname -r) && grep 'model name' /proc/cpuinfo | head -1"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseInfo(text)
    }
  }

  Timer {
    interval: 2000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
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
        spacing: Style.space(10)

        RowLayout {
          Layout.fillWidth: true

          Text {
            text: "System Overview"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            Layout.fillWidth: true
          }

          Text {
            text: root.hostname
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            opacity: 0.6
          }

          Button {
            text: "Close"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            onClicked: root.dismiss()
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 1
          color: Qt.darker(Color.foreground, 2.5)
        }

        Repeater {
          model: ListModel {
            ListElement { label: "Kernel"; value: "kernel" }
            ListElement { label: "CPU"; value: "cpu" }
            ListElement { label: "CPU Usage"; value: "cpuUsage" }
            ListElement { label: "Memory"; value: "mem" }
            ListElement { label: "Disk /"; value: "disk" }
            ListElement { label: "GPU Temp"; value: "gpu" }
            ListElement { label: "Network RX"; value: "netrx" }
            ListElement { label: "Network TX"; value: "nettx" }
            ListElement { label: "Uptime"; value: "uptime" }
          }

          RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: Style.space(8)

            Text {
              text: modelData.label
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              font.bold: true
              Layout.preferredWidth: Style.space(100)
            }

            Text {
              text: {
                switch (modelData.value) {
                  case "kernel": return root.kernel
                  case "cpu": return root.cpuModel
                  case "cpuUsage": return root.cpuUsage
                  case "mem": return root.memUsage + " of " + root.memTotal
                  case "disk": return root.diskUsage
                  case "gpu": return root.gpuTemp
                  case "netrx": return "\u2193 " + root.netRx
                  case "nettx": return "\u2191 " + root.netTx
                  case "uptime": return root.uptime
                  default: return "--"
                }
              }
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              opacity: 0.85
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
          }
        }

        Item { Layout.fillHeight: true }
      }
    }
  }
}
