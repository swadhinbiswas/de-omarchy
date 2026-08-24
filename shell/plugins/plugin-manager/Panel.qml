import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "deomarchy.plugin-manager"
  ipcTarget: "deomarchy.plugin-manager"

  implicitWidth: 700
  implicitHeight: 720

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // ---------------------------------------------------------------- State
  property string currentTab: "installed" // "installed" | "marketplace"
  property var installedPlugins: []
  property var marketplacePlugins: []
  property var filteredInstalled: []
  property var filteredMarketplace: []
  property var shortcutsMap: ({})
  property var barLayoutData: ({ inBar: [] })

  property string installedSearch: ""
  property string installedFilter: "all" // "all" | "active" | "inactive" | "bar" | "builtin" | "user"

  property string marketSearch: ""
  property string marketCategory: "All"
  property string marketSort: "stars" // "stars" | "name" | "date"

  property string installingId: ""
  property string statusMessage: ""
  property string statusType: "info"
  property bool updatingAll: false

  property bool urlDialogOpen: false
  property string urlInput: ""

  property bool confirmUninstallOpen: false
  property var pendingUninstallPlugin: null

  property bool shortcutDialogOpen: false
  property var shortcutTargetPlugin: null
  property string shortcutInput: ""

  property bool barSectionDialogOpen: false
  property var barTargetPlugin: null

  readonly property var registry: root.bar && root.bar.shell
    ? root.bar.shell.pluginRegistry
    : (root.bar ? root.bar.pluginRegistry : null)

  // ---------------------------------------------------------------- Iconography
  //
  // Nerd Font glyph codepoints (same family the bar renders with) instead of
  // colored emoji. Most glyphs live beyond the BMP, so they are stored as
  // ints and resolved with String.fromCodePoint.
  readonly property string nfFontFamily: "JetBrainsMono Nerd Font"
  function nf(code) { return String.fromCodePoint(code) }
  readonly property var ic: ({
    puzzle: 0xF0327,        // md-puzzle
    package: 0xF03D3,       // md-package
    globe: 0xF00AC,         // fa-globe
    magnify: 0xF0349,       // md-magnify
    close: 0xF0156,         // md-close
    check: 0xF012C,         // md-check
    closeCircle: 0xF0159,   // md-close_circle
    checkCircle: 0xF05E0,   // md-check_circle
    pin: 0xF0403,           // md-pin
    plus: 0xF0415,          // md-plus
    keyboard: 0xF097B,      // md-keyboard_outline
    trash: 0xF1F8,          // fa-trash
    star: 0xF04CE           // md-star
  })

  // Per-plugin glyph, mirroring the Plugin Library window's map.
  function getPluginIcon(id) {
    var map = {
      "omarchy.menu": 0xF0463,                // md-rocket
      "omarchy.active-window": 0xF05B1,       // md-window_open
      "omarchy.workspaces": 0xF0570,          // md-view_grid
      "omarchy.bar": 0xF056E,                 // md-view_dashboard
      "omarchy.agents": 0xF06A9,              // md-robot
      "omarchy.audio": 0xF057E,               // md-volume_high
      "omarchy.bluetooth": 0xF00AF,           // md-bluetooth
      "omarchy.network": 0xF05A9,             // md-wifi
      "omarchy.clock": 0xF0150,               // md-clock_outline
      "omarchy.battery": 0xF0079,             // md-battery
      "omarchy.power": 0xF0425,               // md-power
      "omarchy.sysmon": 0xF029A,              // md-gauge
      "omarchy.weather": 0xF0599,             // md-weather_sunny
      "omarchy.media": 0xF075A,               // md-music
      "omarchy.notifications": 0xF009A,       // md-bell
      "omarchy.clipboard": 0xF014D,           // md-clipboard_text
      "omarchy.emojis": 0xF01F2,              // md-emoticon_outline
      "omarchy.indicators": 0xF0335,          // md-lightbulb
      "omarchy.keyboard-layout": 0xF097B,     // md-keyboard_outline
      "omarchy.lock": 0xF033E,                // md-lock
      "omarchy.nightlight": 0xF0594,          // md-weather_night
      "omarchy.microphone": 0xF036C,          // md-microphone
      "omarchy.tray": 0xF1294,                // md-tray
      "omarchy.background": 0xF02E9,          // md-image
      "omarchy.idle": 0xF051F,                // md-timer_sand
      "omarchy.polkit": 0xF0BC5,              // md-shield_key_outline
      "omarchy.reminders": 0xF13AB,           // md-timer
      "omarchy.spacer": 0xF084E,              // md-arrow_expand_horizontal
      "omarchy.speedtest": 0xF04C5,           // md-speedometer
      "omarchy.system-update": 0xF06B0,       // md-update
      "omarchy.tailscale": 0xF0582,           // md-vpn
      "omarchy.wifiqr": 0xF0432,              // md-qrcode
      "deomarchy.docker-status": 0xF0868,     // md-docker
      "deomarchy.wallpaper-manager": 0xF0E09, // md-wallpaper
      "deomarchy.power-profile": 0xF0241,     // md-flash
      "deomarchy.system-overview": 0xF154D,   // md-chart_box
      "deomarchy.monitor-manager": 0xF0379,   // md-monitor
      "deomarchy.plugin-manager": 0xF0327,    // md-puzzle
      "deomarchy.plugin-library": 0xF0327,    // md-puzzle
      "nosignal.motion-wallpaper": 0xF022F,   // md-film
      "omaplug": 0xF06A5                      // md-power_plug
    }
    if (map[id] !== undefined) return String.fromCodePoint(map[id])
    return String.fromCodePoint(0xF0068)        // md-auto_fix
  }

  Component.onCompleted: {
    loadInstalled()
    loadMarketplace()
    loadShortcuts()
    loadBarLayout()
  }

  onOpenedChanged: {
    if (opened) {
      loadInstalled()
      loadMarketplace()
      loadShortcuts()
      loadBarLayout()
    }
  }

  // ---------------------------------------------------------------- Loading
  function loadInstalled() {
    var om = Quickshell.env("OMARCHY_PATH") || "/usr/share/de-omarchy"
    installedProc.command = ["bash", "-c", "omarchy-shell shell listPlugins 2>/dev/null || " + om + "/bin/omarchy-plugins list --json 2>/dev/null || omarchy plugins list --json 2>/dev/null || echo '[]'"]
    installedProc.running = true
  }

  function loadMarketplace() {
    var home = Quickshell.env("HOME")
    var om = Quickshell.env("OMARCHY_PATH") || "/usr/share/de-omarchy"
    marketProc.command = ["bash", "-c", "cat " + home + "/.cache/omarchy/marketplace_catalog.json 2>/dev/null | jq -c '.plugins // []' 2>/dev/null || " + om + "/bin/omarchy-plugins marketplace --json 2>/dev/null || cat " + om + "/registry.json 2>/dev/null | jq -c '.plugins // []' 2>/dev/null || echo '[]'"]
    marketProc.running = true
  }

  function loadShortcuts() {
    shortcutsProc.command = ["bash", "-c", "omarchy plugins shortcut list --json 2>/dev/null || echo '[]'"]
    shortcutsProc.running = true
  }

  function loadBarLayout() {
    barProc.command = ["bash", "-c", "omarchy plugins bar list 2>/dev/null || echo '{\"inBar\":[]}'"]
    barProc.running = true
  }

  Process {
    id: installedProc
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var arr = JSON.parse(String(text).trim())
          if (Array.isArray(arr)) {
            root.installedPlugins = arr
            root.applyInstalledFilter()
          }
        } catch (e) {
          console.warn("Failed to parse installed plugins: " + e)
        }
      }
    }
  }

  Process {
    id: marketProc
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(String(text).trim())
          var arr = Array.isArray(data) ? data : (data && data.plugins ? data.plugins : [])
          if (Array.isArray(arr)) {
            root.marketplacePlugins = arr
            root.applyMarketFilter()
          }
        } catch (e) {
          console.warn("Failed to parse marketplace plugins: " + e)
        }
      }
    }
  }

  Process {
    id: shortcutsProc
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var arr = JSON.parse(String(text).trim())
          var map = {}
          if (Array.isArray(arr)) {
            for (var i = 0; i < arr.length; i++) {
              if (arr[i] && arr[i].id) {
                map[arr[i].id] = arr[i].keys || ""
              }
            }
          }
          root.shortcutsMap = map
        } catch (e) {
          console.warn("Failed to parse shortcuts: " + e)
        }
      }
    }
  }

  Process {
    id: barProc
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(String(text).trim())
          if (data && data.inBar) {
            root.barLayoutData = data
            root.applyInstalledFilter()
          }
        } catch (e) {
          console.warn("Failed to parse bar layout: " + e)
        }
      }
    }
  }

  // ---------------------------------------------------------------- Filtering
  function isPluginInBar(id) {
    if (!id || !root.barLayoutData || !root.barLayoutData.inBar) return false
    return root.barLayoutData.inBar.indexOf(id) !== -1
  }

  function applyInstalledFilter() {
    var list = root.installedPlugins || []
    var q = root.installedSearch.toLowerCase().trim()
    var filter = root.installedFilter

    var res = []
    for (var i = 0; i < list.length; i++) {
      var p = list[i]
      if (filter === "active" && !p.enabled) continue
      if (filter === "inactive" && p.enabled) continue
      if (filter === "bar" && !isPluginInBar(p.id)) continue
      if (filter === "builtin" && !p.firstParty) continue
      if (filter === "user" && p.firstParty) continue

      if (q.length > 0) {
        var name = (p.name || "").toLowerCase()
        var id = (p.id || "").toLowerCase()
        var kinds = (p.kinds || []).join(" ").toLowerCase()
        if (name.indexOf(q) === -1 && id.indexOf(q) === -1 && kinds.indexOf(q) === -1) continue
      }
      res.push(p)
    }
    root.filteredInstalled = res
  }

  function applyMarketFilter() {
    var list = root.marketplacePlugins || []
    var q = root.marketSearch.toLowerCase().trim()
    var cat = root.marketCategory

    var res = []
    for (var i = 0; i < list.length; i++) {
      var p = list[i]
      if (cat !== "All" && (p.category || "").toLowerCase() !== cat.toLowerCase()) continue

      if (q.length > 0) {
        var name = (p.name || "").toLowerCase()
        var id = (p.id || "").toLowerCase()
        var desc = (p.description || "").toLowerCase()
        var author = (p.author || "").toLowerCase()
        var tags = (p.tags || []).join(" ").toLowerCase()
        if (name.indexOf(q) === -1 && id.indexOf(q) === -1 && desc.indexOf(q) === -1 && author.indexOf(q) === -1 && tags.indexOf(q) === -1) continue
      }
      res.push(p)
    }

    if (root.marketSort === "stars") {
      res.sort(function(a, b) { return (b.stars || 0) - (a.stars || 0) })
    } else if (root.marketSort === "name") {
      res.sort(function(a, b) { return (a.name || a.id).localeCompare(b.name || b.id) })
    } else if (root.marketSort === "date") {
      res.sort(function(a, b) { return String(b.addedAt || "").localeCompare(String(a.addedAt || "")) })
    }

    root.filteredMarketplace = res
  }

  onInstalledSearchChanged: applyInstalledFilter()
  onInstalledFilterChanged: applyInstalledFilter()
  onMarketSearchChanged: applyMarketFilter()
  onMarketCategoryChanged: applyMarketFilter()
  onMarketSortChanged: applyMarketFilter()

  // ---------------------------------------------------------------- Helpers
  function isInstalled(id) {
    if (!id) return false
    var cleanId = id.replace(/^[a-z0-9_-]+\./, "")
    for (var i = 0; i < root.installedPlugins.length; i++) {
      var instId = root.installedPlugins[i].id
      if (instId === id || instId === cleanId || instId.endsWith("." + id) || id.endsWith("." + instId)) {
        return true
      }
    }
    return false
  }

  function showToast(msg, type) {
    root.statusMessage = msg
    root.statusType = type || "info"
    toastTimer.restart()
  }

  Timer {
    id: toastTimer
    interval: 3500
    onTriggered: root.statusMessage = ""
  }

  function togglePlugin(plugin) {
    if (!plugin || !plugin.id) return
    var targetState = !plugin.enabled
    plugin.enabled = targetState
    applyInstalledFilter()

    if (root.registry && typeof root.registry.setEnabled === "function") {
      root.registry.setEnabled(plugin.id, targetState)
    }

    actionProc.command = ["bash", "-c", "omarchy plugins " + (targetState ? "enable" : "disable") + " '" + plugin.id + "'"]
    actionProc.targetAction = "toggle"
    actionProc.targetName = plugin.name || plugin.id
    actionProc.targetState = targetState
    actionProc.running = true
  }

  function toggleBarPlacement(plugin) {
    if (!plugin || !plugin.id) return
    if (isPluginInBar(plugin.id)) {
      actionProc.command = ["bash", "-c", "omarchy plugins bar remove '" + plugin.id + "'"]
      actionProc.targetAction = "bar_remove"
      actionProc.targetName = plugin.name || plugin.id
      actionProc.running = true
    } else {
      root.barTargetPlugin = plugin
      root.barSectionDialogOpen = true
    }
  }

  function addPluginToBar(plugin, section) {
    root.barSectionDialogOpen = false
    root.barTargetPlugin = null
    if (!plugin || !plugin.id) return

    showToast("Adding " + (plugin.name || plugin.id) + " to bar (" + section + ")...", "info")
    actionProc.command = ["bash", "-c", "omarchy plugins bar add '" + plugin.id + "' " + section]
    actionProc.targetAction = "bar_add"
    actionProc.targetName = plugin.name || plugin.id
    actionProc.running = true
  }

  function openShortcutDialog(plugin) {
    root.shortcutTargetPlugin = plugin
    root.shortcutInput = root.shortcutsMap[plugin.id] || ""
    root.shortcutDialogOpen = true
  }

  function saveShortcut() {
    var p = root.shortcutTargetPlugin
    var keys = root.shortcutInput.trim()
    root.shortcutDialogOpen = false
    root.shortcutTargetPlugin = null
    if (!p) return

    if (keys === "") {
      actionProc.command = ["bash", "-c", "omarchy plugins shortcut remove '" + p.id + "'"]
      actionProc.targetAction = "shortcut_remove"
      actionProc.targetName = p.name || p.id
      actionProc.running = true
    } else {
      actionProc.command = ["bash", "-c", "omarchy plugins shortcut set '" + p.id + "' '" + keys + "'"]
      actionProc.targetAction = "shortcut_set"
      actionProc.targetName = p.name || p.id
      actionProc.running = true
    }
  }

  function clearShortcut() {
    root.shortcutInput = ""
    saveShortcut()
  }

  function installPlugin(p) {
    if (!p || root.installingId !== "") return
    root.installingId = p.id
    showToast("Installing " + (p.name || p.id) + "...", "info")

    actionProc.command = ["bash", "-c", "omarchy plugins install '" + p.id + "' --enable"]
    actionProc.targetAction = "install"
    actionProc.targetName = p.name || p.id
    actionProc.running = true
  }

  function installFromUrl(url) {
    if (!url || url.trim() === "") return
    url = url.trim()
    root.urlDialogOpen = false
    root.urlInput = ""
    showToast("Installing: " + url + "...", "info")

    actionProc.command = ["bash", "-c", "omarchy plugins install '" + url + "' --enable"]
    actionProc.targetAction = "install"
    actionProc.targetName = url
    actionProc.running = true
  }

  function confirmUninstall(p) {
    root.pendingUninstallPlugin = p
    root.confirmUninstallOpen = true
  }

  function executeUninstall() {
    var p = root.pendingUninstallPlugin
    root.confirmUninstallOpen = false
    root.pendingUninstallPlugin = null
    if (!p) return

    showToast("Removing " + (p.name || p.id) + "...", "info")
    actionProc.command = ["bash", "-c", "omarchy plugins remove '" + p.id + "'"]
    actionProc.targetAction = "remove"
    actionProc.targetName = p.name || p.id
    actionProc.running = true
  }

  Process {
    id: actionProc
    running: false
    property string targetAction: ""
    property string targetName: ""
    property bool targetState: false

    onExited: function(code) {
      root.installingId = ""
      root.updatingAll = false
        if (code === 0) {
          var ok = root.nf(root.ic.checkCircle)
          if (targetAction === "install") {
            root.showToast(ok + " Installed " + targetName + "!", "success")
          } else if (targetAction === "remove") {
            root.showToast(ok + " Removed " + targetName + "!", "success")
          } else if (targetAction === "toggle") {
            root.showToast(ok + " " + (targetState ? "Enabled" : "Disabled") + " " + targetName, "success")
          } else if (targetAction === "bar_add") {
            root.showToast(ok + " Added " + targetName + " to top bar!", "success")
          } else if (targetAction === "bar_remove") {
            root.showToast(ok + " Removed " + targetName + " from bar.", "success")
          } else if (targetAction === "shortcut_set") {
            root.showToast(ok + " Shortcut saved for " + targetName + "!", "success")
          } else if (targetAction === "shortcut_remove") {
            root.showToast(ok + " Shortcut cleared for " + targetName, "success")
          }
        } else {
          root.showToast(root.nf(root.ic.closeCircle) + " Action failed for " + targetName, "error")
        }
      root.loadInstalled()
      root.loadShortcuts()
      root.loadBarLayout()
    }
  }

  function getInitials(name) {
    if (!name) return "?"
    var parts = name.split(/[\s.-]+/)
    if (parts.length >= 2 && parts[0].length > 0 && parts[1].length > 0) {
      return (parts[0][0] + parts[1][0]).toUpperCase()
    }
    return name.substring(0, Math.min(2, name.length)).toUpperCase()
  }

  // ---------------------------------------------------------------- Content Layout
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 14
    spacing: 12

    // Header
    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      Text {
        text: root.nf(root.ic.puzzle) + " Plugin Manager"
        color: Color.foreground
        font.family: root.nfFontFamily
        font.pixelSize: 18
        font.bold: true
      }

      Item { Layout.fillWidth: true }

      // Tab switcher
      Rectangle {
        Layout.preferredWidth: 260
        Layout.preferredHeight: 32
        radius: 16
        color: Qt.rgba(0, 0, 0, 0.25)
        border.color: Qt.rgba(255, 255, 255, 0.08)
        border.width: 1

        RowLayout {
          anchors.fill: parent
          spacing: 0

          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: root.currentTab === "installed" ? Color.accent : "transparent"

            Text {
              anchors.centerIn: parent
              text: root.nf(root.ic.package) + " Installed (" + root.installedPlugins.length + ")"
              color: root.currentTab === "installed" ? Color.background : Color.foreground
              font.family: root.nfFontFamily
              font.pixelSize: 11
              font.bold: root.currentTab === "installed"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.currentTab = "installed"
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: root.currentTab === "marketplace" ? Color.accent : "transparent"

            Text {
              anchors.centerIn: parent
              text: root.nf(root.ic.globe) + " Marketplace"
              color: root.currentTab === "marketplace" ? Color.background : Color.foreground
              font.family: root.nfFontFamily
              font.pixelSize: 11
              font.bold: root.currentTab === "marketplace"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.currentTab = "marketplace"
                if (root.marketplacePlugins.length === 0) root.loadMarketplace()
              }
            }
          }
        }
      }

      // Add Git URL Button
      Rectangle {
        Layout.preferredHeight: 30
        Layout.preferredWidth: 32
        radius: 6
        color: Qt.rgba(255, 255, 255, 0.08)
        border.color: Qt.rgba(255, 255, 255, 0.12)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "+"
          color: Color.foreground
          font.pixelSize: 16
          font.bold: true
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.urlDialogOpen = true
        }
      }
    }

    // Status Banner Toast
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: root.statusMessage !== "" ? 30 : 0
      visible: root.statusMessage !== ""
      radius: 6
      color: root.statusType === "success" ? Qt.rgba(0.2, 0.8, 0.3, 0.2) : Qt.rgba(0.3, 0.6, 0.9, 0.2)
      border.color: root.statusType === "success" ? "#a6e3a1" : "#89b4fa"
      border.width: 1
      clip: true

      Text {
        anchors.centerIn: parent
        text: root.statusMessage
        color: Color.foreground
        font.pixelSize: 11
        font.bold: true
      }
    }

    // Stack Views
    StackLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      currentIndex: root.currentTab === "installed" ? 0 : 1

      // TAB 1: INSTALLED
      Item {
        ColumnLayout {
          anchors.fill: parent
          spacing: 8

          // Search Bar
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.2)
            border.color: Qt.rgba(255, 255, 255, 0.1)
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: 6
              spacing: 6
              Text { text: root.nf(root.ic.magnify); font.family: root.nfFontFamily; font.pixelSize: 11; color: Color.subtext }
              TextInput {
                id: installedSearchField
                Layout.fillWidth: true
                text: root.installedSearch
                color: Color.foreground
                font.pixelSize: 11
                onTextChanged: root.installedSearch = text
                Text {
                  text: "Filter installed..."
                  color: Color.subtext
                  font.pixelSize: 11
                  visible: !installedSearchField.text
                }
              }
            }
          }

          // Filter Chips
          RowLayout {
            spacing: 6
            Repeater {
              model: [
                { id: "all", label: "All" },
                { id: "active", label: "Active" },
                { id: "inactive", label: "Inactive" },
                { id: "bar", label: "In Bar" },
                { id: "user", label: "User" }
              ]
              delegate: Rectangle {
                required property var modelData
                Layout.preferredHeight: 24
                Layout.preferredWidth: chipText.implicitWidth + 14
                radius: 12
                color: root.installedFilter === modelData.id ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.25) : Qt.rgba(255, 255, 255, 0.05)
                border.color: root.installedFilter === modelData.id ? Color.accent : "transparent"
                border.width: 1

                Text {
                  id: chipText
                  anchors.centerIn: parent
                  text: modelData.label
                  color: Color.foreground
                  font.pixelSize: 10
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.installedFilter = modelData.id
                }
              }
            }
          }

          // List
          ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.filteredInstalled

            delegate: Rectangle {
              required property var modelData
              property bool inBar: root.isPluginInBar(modelData.id)
              property string shortcut: root.shortcutsMap[modelData.id] || ""
              property bool isBarCompatible: {
                var kinds = modelData.kinds || []
                return kinds.indexOf("bar-widget") !== -1 || kinds.indexOf("bar") !== -1 || kinds.indexOf("panel") !== -1
              }

              width: parent.width
              height: 66
              radius: 8
              color: Qt.rgba(255, 255, 255, modelData.enabled ? 0.08 : 0.03)
              border.color: Qt.rgba(255, 255, 255, 0.08)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                  Layout.preferredWidth: 36
                  Layout.preferredHeight: 36
                  radius: 8
                  color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.2)
                  Text {
                    anchors.centerIn: parent
                    text: root.getPluginIcon(modelData.id)
                    color: Color.accent
                    font.family: root.nfFontFamily
                    font.pixelSize: 18
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2
                  Text {
                    text: modelData.name || modelData.id
                    color: Color.foreground
                    font.pixelSize: 12
                    font.bold: true
                  }
                  Text {
                    text: modelData.id + (modelData.firstParty ? " (Built-in)" : " (User)")
                    color: Color.subtext
                    font.pixelSize: 10
                  }
                }

                // Bar placement toggle
                Rectangle {
                  visible: isBarCompatible
                  Layout.preferredHeight: 26
                  Layout.preferredWidth: pBarText.implicitWidth + 12
                  radius: 4
                  color: inBar ? Qt.rgba(0.2, 0.8, 0.3, 0.18) : Qt.rgba(255, 255, 255, 0.06)
                  border.color: inBar ? "#a6e3a1" : Qt.rgba(255, 255, 255, 0.1)
                  border.width: 1

                  Text {
                    id: pBarText
                    anchors.centerIn: parent
                    text: inBar ? root.nf(root.ic.pin) + " In Bar" : root.nf(root.ic.plus) + " Bar"
                    color: inBar ? "#a6e3a1" : Color.subtext
                    font.family: root.nfFontFamily
                    font.pixelSize: 9
                    font.bold: inBar
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleBarPlacement(modelData)
                  }
                }

                // Shortcut button
                Rectangle {
                  Layout.preferredHeight: 26
                  Layout.preferredWidth: pScText.implicitWidth + 12
                  radius: 4
                  color: shortcut !== "" ? Qt.rgba(1, 0.7, 0.2, 0.18) : Qt.rgba(255, 255, 255, 0.06)
                  border.color: shortcut !== "" ? "#ff9e64" : Qt.rgba(255, 255, 255, 0.1)
                  border.width: 1

                  Text {
                    id: pScText
                    anchors.centerIn: parent
                    text: root.nf(root.ic.keyboard) + (shortcut !== "" ? " " + shortcut : " Key")
                    color: shortcut !== "" ? "#ff9e64" : Color.subtext
                    font.family: root.nfFontFamily
                    font.pixelSize: 9
                    font.bold: shortcut !== ""
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openShortcutDialog(modelData)
                  }
                }

                // Delete button for user plugins
                Rectangle {
                  visible: !modelData.firstParty
                  Layout.preferredWidth: 26
                  Layout.preferredHeight: 26
                  radius: 4
                  color: Qt.rgba(1, 0, 0, 0.15)
                  Text { anchors.centerIn: parent; text: root.nf(root.ic.trash); font.family: root.nfFontFamily; font.pixelSize: 12; color: "#f7768e" }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.confirmUninstall(modelData)
                  }
                }

                // Switch
                Rectangle {
                  Layout.preferredWidth: 44
                  Layout.preferredHeight: 24
                  radius: 12
                  color: modelData.enabled ? Color.accent : Qt.rgba(255, 255, 255, 0.15)
                  border.color: Qt.rgba(255, 255, 255, 0.1)
                  border.width: 1

                  Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                    x: modelData.enabled ? 22 : 4
                    Behavior on x { NumberAnimation { duration: 120 } }
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.togglePlugin(modelData)
                  }
                }
              }
            }
          }
        }
      }

      // TAB 2: MARKETPLACE
      Item {
        ColumnLayout {
          anchors.fill: parent
          spacing: 8

          // Search Bar
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.2)
            border.color: Qt.rgba(255, 255, 255, 0.1)
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: 6
              spacing: 6
              Text { text: root.nf(root.ic.globe); font.family: root.nfFontFamily; font.pixelSize: 11; color: Color.subtext }
              TextInput {
                id: marketSearchField
                Layout.fillWidth: true
                text: root.marketSearch
                color: Color.foreground
                font.pixelSize: 11
                onTextChanged: root.marketSearch = text
                Text {
                  text: "Search 1,000+ plugins..."
                  color: Color.subtext
                  font.pixelSize: 11
                  visible: !marketSearchField.text
                }
              }
            }
          }

          // Category Chips
          ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            RowLayout {
              spacing: 6
              Repeater {
                model: ["All", "Appearance", "Desktop", "Productivity", "System", "Utilities", "Widgets"]
                delegate: Rectangle {
                  required property var modelData
                  Layout.preferredHeight: 24
                  Layout.preferredWidth: mCatText.implicitWidth + 14
                  radius: 12
                  color: root.marketCategory === modelData ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.25) : Qt.rgba(255, 255, 255, 0.05)
                  border.color: root.marketCategory === modelData ? Color.accent : "transparent"
                  border.width: 1

                  Text {
                    id: mCatText
                    anchors.centerIn: parent
                    text: modelData
                    color: Color.foreground
                    font.pixelSize: 10
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.marketCategory = modelData
                  }
                }
              }
            }
          }

          // List
          ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.filteredMarketplace

            delegate: Rectangle {
              required property var modelData
              property bool installed: root.isInstalled(modelData.id)
              width: parent.width
              height: 74
              radius: 8
              color: Qt.rgba(255, 255, 255, 0.05)
              border.color: Qt.rgba(255, 255, 255, 0.08)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Rectangle {
                  Layout.preferredWidth: 38
                  Layout.preferredHeight: 38
                  radius: 8
                  color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.2)
                  Text {
                    anchors.centerIn: parent
                    text: modelData.initials || root.getInitials(modelData.name || modelData.id)
                    color: Color.foreground
                    font.pixelSize: 13
                    font.bold: true
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2
                  RowLayout {
                    spacing: 6
                    Text {
                      text: modelData.name || modelData.id
                      color: Color.foreground
                      font.pixelSize: 12
                      font.bold: true
                    }
                    Text {
                      visible: (modelData.stars || 0) > 0
                      text: root.nf(root.ic.star) + " " + modelData.stars
                      color: "#e0af68"
                      font.family: root.nfFontFamily
                      font.pixelSize: 10
                    }
                  }
                  Text {
                    Layout.fillWidth: true
                    text: modelData.description || ""
                    color: Color.subtext
                    font.pixelSize: 10
                    elide: Text.ElideRight
                  }
                }

                // Install button
                Rectangle {
                  Layout.preferredHeight: 28
                  Layout.preferredWidth: installed ? 78 : 66
                  radius: 6
                  color: installed ? Qt.rgba(0.2, 0.8, 0.3, 0.18) : (root.installingId === modelData.id ? Qt.rgba(255, 255, 255, 0.08) : Color.accent)
                  border.color: installed ? "#a6e3a1" : "transparent"
                  border.width: installed ? 1 : 0

                  Text {
                    anchors.centerIn: parent
                    text: installed ? root.nf(root.ic.check) + " Installed" : (root.installingId === modelData.id ? "..." : "Install")
                    color: installed ? "#a6e3a1" : (root.installingId === modelData.id ? Color.subtext : Color.background)
                    font.family: root.nfFontFamily
                    font.pixelSize: 10
                    font.bold: true
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !installed && root.installingId === ""
                    onClicked: root.installPlugin(modelData)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // Modals
  // 1. Shortcut Dialog
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.75)
    visible: root.shortcutDialogOpen

    MouseArea { anchors.fill: parent; onClicked: root.shortcutDialogOpen = false }

    Rectangle {
      anchors.centerIn: parent
      width: 440
      height: 240
      radius: 10
      color: Color.popups ? Color.popups.background : "#1f2335"
      border.color: "#ff9e64"
      border.width: 1

      MouseArea { anchors.fill: parent }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
          text: root.nf(root.ic.keyboard) + " Set Keyboard Shortcut"
          color: Color.foreground
          font.family: root.nfFontFamily
          font.pixelSize: 14
          font.bold: true
        }

        Text {
          text: "Set Hyprland keybind for '" + (root.shortcutTargetPlugin ? (root.shortcutTargetPlugin.name || root.shortcutTargetPlugin.id) : "") + "':"
          color: Color.subtext
          font.pixelSize: 11
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 34
          radius: 6
          color: Qt.rgba(0, 0, 0, 0.25)
          border.color: "#ff9e64"
          border.width: 1

          TextInput {
            anchors.fill: parent
            anchors.margins: 6
            text: root.shortcutInput
            color: Color.foreground
            font.pixelSize: 12
            font.bold: true
            onTextChanged: root.shortcutInput = text
            Text {
              text: "e.g. SUPER + ALT + D"
              color: Color.subtext
              font.pixelSize: 11
              visible: !parent.text
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Button {
            text: "Clear"
            onClicked: root.clearShortcut()
          }
          Item { Layout.fillWidth: true }
          Button {
            text: "Cancel"
            onClicked: root.shortcutDialogOpen = false
          }
          Button {
            text: "Save & Apply"
            onClicked: root.saveShortcut()
          }
        }
      }
    }
  }

  // 2. Bar Section Selector
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.75)
    visible: root.barSectionDialogOpen

    MouseArea { anchors.fill: parent; onClicked: root.barSectionDialogOpen = false }

    Rectangle {
      anchors.centerIn: parent
      width: 380
      height: 180
      radius: 10
      color: Color.popups ? Color.popups.background : "#1f2335"
      border.color: "#a6e3a1"
      border.width: 1

      MouseArea { anchors.fill: parent }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
          text: root.nf(root.ic.pin) + " Add to Omarchy Top Bar"
          color: Color.foreground
          font.pixelSize: 14
          font.bold: true
        }

        Text {
          text: "Select bar section:"
          color: Color.subtext
          font.pixelSize: 11
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Button {
            Layout.fillWidth: true
            text: "Left"
            onClicked: root.addPluginToBar(root.barTargetPlugin, "left")
          }
          Button {
            Layout.fillWidth: true
            text: "Center"
            onClicked: root.addPluginToBar(root.barTargetPlugin, "center")
          }
          Button {
            Layout.fillWidth: true
            text: "Right"
            onClicked: root.addPluginToBar(root.barTargetPlugin, "right")
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Item { Layout.fillWidth: true }
          Button {
            text: "Cancel"
            onClicked: root.barSectionDialogOpen = false
          }
        }
      }
    }
  }

  // 3. Git URL Dialog Modal
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.7)
    visible: root.urlDialogOpen

    MouseArea { anchors.fill: parent; onClicked: root.urlDialogOpen = false }

    Rectangle {
      anchors.centerIn: parent
      width: 420
      height: 180
      radius: 10
      color: Color.popups ? Color.popups.background : "#1f2335"
      border.color: Qt.rgba(255, 255, 255, 0.15)
      border.width: 1

      MouseArea { anchors.fill: parent }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
          text: "Install from Git Repository"
          color: Color.foreground
          font.pixelSize: 14
          font.bold: true
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 34
          radius: 6
          color: Qt.rgba(0, 0, 0, 0.25)
          border.color: Color.accent
          border.width: 1

          TextInput {
            anchors.fill: parent
            anchors.margins: 6
            text: root.urlInput
            color: Color.foreground
            font.pixelSize: 11
            onTextChanged: root.urlInput = text
            Text {
              text: "https://github.com/..."
              color: Color.subtext
              font.pixelSize: 11
              visible: !parent.text
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Item { Layout.fillWidth: true }
          Button {
            text: "Cancel"
            onClicked: root.urlDialogOpen = false
          }
          Button {
            text: "Install"
            onClicked: root.installFromUrl(root.urlInput)
          }
        }
      }
    }
  }

  // 4. Confirm Uninstall Dialog
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.7)
    visible: root.confirmUninstallOpen

    MouseArea { anchors.fill: parent; onClicked: root.confirmUninstallOpen = false }

    Rectangle {
      anchors.centerIn: parent
      width: 380
      height: 150
      radius: 10
      color: Color.popups ? Color.popups.background : "#1f2335"
      border.color: Qt.rgba(255, 255, 255, 0.15)
      border.width: 1

      MouseArea { anchors.fill: parent }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
          text: "Uninstall Plugin"
          color: "#f7768e"
          font.pixelSize: 14
          font.bold: true
        }

        Text {
          text: "Remove '" + (root.pendingUninstallPlugin ? (root.pendingUninstallPlugin.name || root.pendingUninstallPlugin.id) : "") + "'?"
          color: Color.foreground
          font.pixelSize: 11
        }

        RowLayout {
          Layout.fillWidth: true
          Item { Layout.fillWidth: true }
          Button {
            text: "Cancel"
            onClicked: root.confirmUninstallOpen = false
          }
          Button {
            text: "Remove"
            onClicked: root.executeUninstall()
          }
        }
      }
    }
  }
}
