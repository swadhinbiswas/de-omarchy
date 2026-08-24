import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root

  // ---------------------------------------------------------------- Visual Design System (Tokyo Night / Catppuccin inspired)
  readonly property color bgBase: "#11121d"
  readonly property color bgSurface: "#161726"
  readonly property color bgCard: "#1d1f33"
  readonly property color bgCardHover: "#252842"
  readonly property color bgElevated: "#2a2e4a"
  readonly property color borderSubtle: "#282b45"
  readonly property color borderActive: "#3d426b"

  readonly property color fgMain: "#cdd6f4"
  readonly property color fgMuted: "#a6adc8"
  readonly property color fgDim: "#585b70"

  readonly property color accent: "#89b4fa"
  readonly property color accentGlow: Qt.rgba(137/255, 180/255, 250/255, 0.15)

  readonly property color greenSuccess: "#a6e3a1"
  readonly property color greenGlow: Qt.rgba(166/255, 227/255, 161/255, 0.15)

  readonly property color redDanger: "#f38ba8"
  readonly property color redGlow: Qt.rgba(243/255, 139/255, 168/255, 0.15)

  readonly property color amberWarn: "#fab387"
  readonly property color amberGlow: Qt.rgba(250/255, 179/255, 135/255, 0.15)

  readonly property color purpleTag: "#cba6f7"
  readonly property color purpleGlow: Qt.rgba(203/255, 166/255, 247/255, 0.15)

  // ---------------------------------------------------------------- Iconography
  //
  // Vector glyphs from JetBrainsMono Nerd Font — the family the bar, panels,
  // and terminal already render with — so icons stay monochrome, crisp at
  // every size, and tintable instead of colored emoji. Most Nerd Font
  // codepoints live beyond the BMP, so they are stored as ints and resolved
  // with String.fromCodePoint rather than \u escapes.
  readonly property string nfFontFamily: "JetBrainsMono Nerd Font"
  function nf(code) { return String.fromCodePoint(code) }

  // Chrome icons used by this window's own controls.
  readonly property var ic: ({
    puzzle: 0xF0327,        // md-puzzle            plugin manager brand
    package: 0xF03D3,       // md-package           installed tab
    globe: 0xF00AC,         // fa-globe             marketplace tab / web search
    plus: 0xF0415,          // md-plus              add / pin actions
    update: 0xF06B0,        // md-update            update-all button
    bolt: 0xF140B,          // md-lightning_bolt    restart shell
    magnify: 0xF0349,       // md-magnify           search fields
    close: 0xF0156,         // md-close             clear buttons
    check: 0xF012C,         // md-check             success states
    closeCircle: 0xF0159,   // md-close_circle      failure states
    checkCircle: 0xF05E0,   // md-check_circle      success toasts
    pin: 0xF0403,           // md-pin               bar placement
    keyboard: 0xF097B,      // md-keyboard_outline  shortcut keycap
    trash: 0xF1F8,          // fa-trash             remove user plugin
    star: 0xF04CE,          // md-star              marketplace stars
    externalLink: 0xF005C,  // md-arrow_top_right   repo link
    arrowLeft: 0xF004D,     // md-arrow_left        section picker
    arrowRight: 0xF0054     // md-arrow_right       section picker
  })

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
  property string statusType: "info" // "info" | "success" | "error"
  property bool updatingAll: false

  // Modals
  property bool urlDialogOpen: false
  property string urlInput: ""

  property bool confirmUninstallOpen: false
  property var pendingUninstallPlugin: null

  property bool restartDialogOpen: false

  property bool shortcutDialogOpen: false
  property var shortcutTargetPlugin: null
  property string shortcutInput: ""

  property bool barSectionDialogOpen: false
  property var barTargetPlugin: null

  Component.onCompleted: {
    loadInstalled()
    loadMarketplace()
    loadShortcuts()
    loadBarLayout()
  }

  // ---------------------------------------------------------------- Data Loaders
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

  // ---------------------------------------------------------------- Filter Logic
  function isPluginInBar(id) {
    if (!id || !root.barLayoutData || !root.barLayoutData.inBar) return false
    return root.barLayoutData.inBar.indexOf(id) !== -1
  }

  function getPluginIcon(id, name) {
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
    var clean = (name || id || "").toLowerCase()
    if (clean.indexOf("docker") !== -1) return String.fromCodePoint(0xF0868) // md-docker
    if (clean.indexOf("game") !== -1) return String.fromCodePoint(0xF0296)   // md-gamepad
    if (clean.indexOf("music") !== -1 || clean.indexOf("audio") !== -1) return String.fromCodePoint(0xF075A) // md-music
    if (clean.indexOf("wall") !== -1) return String.fromCodePoint(0xF02E9)   // md-image
    if (clean.indexOf("monitor") !== -1 || clean.indexOf("cpu") !== -1) return String.fromCodePoint(0xF029A) // md-gauge
    if (clean.indexOf("calc") !== -1) return String.fromCodePoint(0xF00EC)   // md-calculator
    if (clean.indexOf("ai") !== -1 || clean.indexOf("gpt") !== -1) return String.fromCodePoint(0xF06A9) // md-robot
    return String.fromCodePoint(0xF0068)                                     // md-auto_fix
  }

  function getPluginDescription(p) {
    if (p.description && p.description.length > 0) return p.description
    var map = {
      "omarchy.active-window": "Displays the title and icon of the current focused window",
      "omarchy.agents": "Quick switcher and status for background AI coding assistants",
      "omarchy.audio": "Audio volume slider, output sink switcher, and per-app stream mixer",
      "omarchy.background": "High-performance wallpaper backdrop rendering service",
      "omarchy.bar": "Core desktop top bar container and layout supervisor",
      "omarchy.battery": "Battery level indicator, charging status, and power threshold alerts",
      "omarchy.bluetooth": "Bluetooth device scanner, pairing manager, and quick connect",
      "omarchy.clipboard": "Searchable clipboard history popup overlay",
      "omarchy.clock": "Date, time, world clocks, and integrated monthly calendar panel",
      "omarchy.dev-gallery": "Developer gallery showcase for Quickshell UI components",
      "omarchy.disk-speedtest": "Real-time disk read/write benchmark utility",
      "omarchy.dropbox": "Dropbox file sync state and folder shortcut",
      "omarchy.emojis": "Searchable emoji picker with instant clipboard copy",
      "omarchy.idle": "Wayland idle manager and automatic screen locking service",
      "omarchy.image-picker": "Desktop screenshot and image selector overlay",
      "omarchy.indicators": "Quick-glance system status indicators (caps lock, mute, recording)",
      "omarchy.keyboard-layout": "Keyboard layout indicator and XKB switcher",
      "omarchy.lock": "Wayland lock screen overlay with password authentication",
      "omarchy.media": "MPRIS media player controls (play/pause, track, seek)",
      "omarchy.menu": "Application launcher and system command launcher",
      "omarchy.microphone": "Microphone volume control and mute toggle",
      "omarchy.monitor": "Display arrangement, brightness, and resolution manager",
      "nosignal.motion-wallpaper": "Dynamic animated video and shader wallpaper background",
      "omarchy.network": "Wi-Fi network scanner, signal strength, and Ethernet status",
      "omarchy.nightlight": "Blue light reduction gamma adjustment service (Hyprsunset)",
      "omarchy.notifications": "Desktop notification center and daemon",
      "omarchy.osd": "On-screen display popup for volume and brightness adjustments",
      "omarchy.polkit": "Polkit authentication agent for administrative privilege prompts",
      "omarchy.power": "Power menu with shutdown, reboot, suspend, and logout options",
      "omarchy.reminders": "Sticky notes and system reminder overlay",
      "omarchy.spacer": "Flexible spacer element for custom bar layout separation",
      "omarchy.speedtest": "Network internet speed test benchmark panel",
      "omarchy.sysmon": "Live CPU, RAM, disk, network, and temperature monitor",
      "omarchy.system-update": "Arch Linux pacman & AUR package update notification widget",
      "omarchy.tailscale": "Tailscale VPN status toggle and exit node switcher",
      "omarchy.tray": "System tray host for background app indicators",
      "omarchy.weather": "Local weather forecast and temperature indicator",
      "omarchy.wifiqr": "Generates a Wi-Fi QR code for quick mobile connection",
      "omarchy.workspaces": "Visual Hyprland workspace indicator with active window dots",
      "deomarchy.docker-status": "Docker container monitor with one-click lazydocker integration",
      "deomarchy.power-profile": "Power profile switcher (Performance / Balanced / Power-saver)",
      "deomarchy.wallpaper-manager": "Theme-synchronized wallpaper selector panel",
      "deomarchy.system-overview": "Comprehensive system resource overview dashboard"
    }
    return map[p.id] || ("ID: " + p.id)
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
        var desc = getPluginDescription(p).toLowerCase()
        var kinds = (p.kinds || []).join(" ").toLowerCase()
        if (name.indexOf(q) === -1 && id.indexOf(q) === -1 && desc.indexOf(q) === -1 && kinds.indexOf(q) === -1) continue
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

  // ---------------------------------------------------------------- Actions
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

  function updateAllPlugins() {
    root.updatingAll = true
    showToast("Checking and updating all plugins...", "info")
    actionProc.command = ["bash", "-c", "omarchy plugins update"]
    actionProc.targetAction = "update_all"
    actionProc.targetName = "all plugins"
    actionProc.running = true
  }

  function restartShell() {
    root.restartDialogOpen = false
    showToast("Restarting Quickshell...", "info")
    actionProc.command = ["bash", "-c", "omarchy-restart-shell"]
    actionProc.targetAction = "restart"
    actionProc.targetName = "shell"
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
            root.showToast(ok + " Removed " + targetName + ".", "success")
          } else if (targetAction === "toggle") {
            root.showToast(ok + " " + (targetState ? "Enabled" : "Disabled") + " " + targetName, "success")
          } else if (targetAction === "bar_add") {
            root.showToast(ok + " Pinned " + targetName + " to top bar!", "success")
          } else if (targetAction === "bar_remove") {
            root.showToast(ok + " Unpinned " + targetName + " from bar.", "success")
          } else if (targetAction === "shortcut_set") {
            root.showToast(ok + " Shortcut saved for " + targetName + "!", "success")
          } else if (targetAction === "shortcut_remove") {
            root.showToast(ok + " Shortcut cleared for " + targetName, "success")
          } else if (targetAction === "update_all") {
            root.showToast(ok + " All plugins up to date!", "success")
          } else if (targetAction === "restart") {
            root.showToast(ok + " Shell restarted successfully!", "success")
          }
        } else {
          root.showToast(root.nf(root.ic.closeCircle) + " Operation failed for " + targetName, "error")
        }
      root.loadInstalled()
      root.loadShortcuts()
      root.loadBarLayout()
    }
  }

  // ---------------------------------------------------------------- Main Floating Window
  Window {
    id: win
    title: "Omarchy Plugin Manager"
    visible: true
    width: 980
    height: 740
    minimumWidth: 840
    minimumHeight: 600
    color: root.bgBase

    Rectangle {
      anchors.fill: parent
      color: root.bgBase

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ========================================================== Top Navigation Header
        RowLayout {
          Layout.fillWidth: true
          spacing: 16

          // Left Brand
          RowLayout {
            spacing: 12
            Rectangle {
              Layout.preferredWidth: 42
              Layout.preferredHeight: 42
              radius: 12
              color: root.accentGlow
              border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.4)
              border.width: 1
              Text {
                anchors.centerIn: parent
                text: root.nf(root.ic.puzzle)
                color: root.accent
                font.family: root.nfFontFamily
                font.pixelSize: 22
              }
            }

            ColumnLayout {
              spacing: 2
              Text {
                text: "Plugin Manager"
                color: root.fgMain
                font.pixelSize: 18
                font.bold: true
              }
              Text {
                text: "Omarchy Desktop & Extensions"
                color: root.fgMuted
                font.pixelSize: 11
              }
            }
          }

          Item { Layout.fillWidth: true }

          // Center Segmented Tab Bar
          Rectangle {
            Layout.preferredWidth: 320
            Layout.preferredHeight: 40
            radius: 20
            color: root.bgSurface
            border.color: root.borderSubtle
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: 4
              spacing: 4

              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: root.currentTab === "installed" ? root.accent : "transparent"

                RowLayout {
                  anchors.centerIn: parent
                  spacing: 6
                  Text {
                    text: root.nf(root.ic.package)
                    color: root.currentTab === "installed" ? "#11121d" : root.fgMuted
                    font.family: root.nfFontFamily
                    font.pixelSize: 13
                  }
                  Text {
                    text: "Installed (" + root.installedPlugins.length + ")"
                    color: root.currentTab === "installed" ? "#11121d" : root.fgMuted
                    font.pixelSize: 12
                    font.bold: root.currentTab === "installed"
                  }
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
                radius: 16
                color: root.currentTab === "marketplace" ? root.accent : "transparent"

                RowLayout {
                  anchors.centerIn: parent
                  spacing: 6
                  Text {
                    text: root.nf(root.ic.globe)
                    color: root.currentTab === "marketplace" ? "#11121d" : root.fgMuted
                    font.family: root.nfFontFamily
                    font.pixelSize: 13
                  }
                  Text {
                    text: "Marketplace (" + (root.marketplacePlugins.length || "1000+") + ")"
                    color: root.currentTab === "marketplace" ? "#11121d" : root.fgMuted
                    font.pixelSize: 12
                    font.bold: root.currentTab === "marketplace"
                  }
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

          Item { Layout.fillWidth: true }

          // Right Actions
          RowLayout {
            spacing: 8

            // Git URL
            Rectangle {
              Layout.preferredHeight: 36
              Layout.preferredWidth: btnGitText.implicitWidth + 28
              radius: 10
              color: root.bgSurface
              border.color: root.borderSubtle
              border.width: 1

              RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text {
                  text: root.nf(root.ic.plus)
                  color: root.accent
                  font.family: root.nfFontFamily
                  font.pixelSize: 13
                }
                Text {
                  id: btnGitText
                  text: "Git URL"
                  color: root.fgMain
                  font.pixelSize: 12
                  font.bold: true
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.urlDialogOpen = true
              }
            }

            // Update All
            Rectangle {
              Layout.preferredHeight: 36
              Layout.preferredWidth: btnUpText.implicitWidth + 28
              radius: 10
              color: root.bgSurface
              border.color: root.borderSubtle
              border.width: 1

              RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text {
                  text: root.nf(root.ic.update)
                  color: root.greenSuccess
                  font.family: root.nfFontFamily
                  font.pixelSize: 13
                }
                Text {
                  id: btnUpText
                  text: "Update"
                  color: root.fgMain
                  font.pixelSize: 12
                  font.bold: true
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.updateAllPlugins()
              }
            }

            // Restart Shell
            Rectangle {
              Layout.preferredHeight: 36
              Layout.preferredWidth: 38
              radius: 10
              color: root.bgSurface
              border.color: root.borderSubtle
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: root.nf(root.ic.bolt)
                color: root.fgMain
                font.family: root.nfFontFamily
                font.pixelSize: 15
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.restartDialogOpen = true
              }
            }
          }
        }

        // ========================================================== Toast Banner
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: root.statusMessage !== "" ? 36 : 0
          visible: root.statusMessage !== ""
          radius: 10
          color: root.statusType === "success" ? root.greenGlow : (root.statusType === "error" ? root.redGlow : root.accentGlow)
          border.color: root.statusType === "success" ? root.greenSuccess : (root.statusType === "error" ? root.redDanger : root.accent)
          border.width: 1
          clip: true

          Text {
            anchors.centerIn: parent
            text: root.statusMessage
            color: root.fgMain
            font.family: root.nfFontFamily
            font.pixelSize: 12
            font.bold: true
          }
        }

        // ========================================================== Views
        StackLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          currentIndex: root.currentTab === "installed" ? 0 : 1

          // -------------------------------------------------------- TAB 1: INSTALLED
          Item {
            ColumnLayout {
              anchors.fill: parent
              spacing: 12

              // Filter & Search Toolbar
              RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Search Box
                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 40
                  radius: 12
                  color: root.bgSurface
                  border.color: root.borderSubtle
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                      text: root.nf(root.ic.magnify)
                      color: root.fgDim
                      font.family: root.nfFontFamily
                      font.pixelSize: 14
                    }

                    TextInput {
                      id: installedSearchInput
                      Layout.fillWidth: true
                      text: root.installedSearch
                      color: root.fgMain
                      font.pixelSize: 13
                      selectByMouse: true
                      onTextChanged: root.installedSearch = text

                      Text {
                        text: "Search plugins by name, ID, or description..."
                        color: root.fgDim
                        font.pixelSize: 13
                        visible: !installedSearchInput.text
                      }
                    }

                    Text {
                      visible: installedSearchInput.text.length > 0
                      text: root.nf(root.ic.close)
                      color: root.fgDim
                      font.family: root.nfFontFamily
                      font.pixelSize: 13
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.installedSearch = ""
                      }
                    }
                  }
                }

                // Filter Chips
                RowLayout {
                  spacing: 6

                  Repeater {
                    model: [
                      { id: "all", label: "All (" + root.installedPlugins.length + ")" },
                      { id: "active", label: "Active" },
                      { id: "inactive", label: "Inactive" },
                      { id: "bar", label: "In Bar" },
                      { id: "builtin", label: "Built-in" },
                      { id: "user", label: "User" }
                    ]

                    delegate: Rectangle {
                      required property var modelData
                      Layout.preferredHeight: 34
                      Layout.preferredWidth: instChipText.implicitWidth + 22
                      radius: 17
                      color: root.installedFilter === modelData.id ? root.accentGlow : root.bgSurface
                      border.color: root.installedFilter === modelData.id ? root.accent : root.borderSubtle
                      border.width: 1

                      Text {
                        id: instChipText
                        anchors.centerIn: parent
                        text: modelData.label
                        color: root.installedFilter === modelData.id ? root.accent : root.fgMuted
                        font.pixelSize: 12
                        font.bold: root.installedFilter === modelData.id
                      }

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.installedFilter = modelData.id
                      }
                    }
                  }
                }
              }

              // List of Installed Plugins
              ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: root.filteredInstalled

                delegate: Rectangle {
                  required property var modelData
                  property bool inBar: root.isPluginInBar(modelData.id)
                  property string shortcut: root.shortcutsMap[modelData.id] || ""
                  property bool isBarCompatible: {
                    var kinds = modelData.kinds || []
                    return kinds.indexOf("bar-widget") !== -1 || kinds.indexOf("bar") !== -1 || kinds.indexOf("panel") !== -1
                  }

                  width: parent ? parent.width : 0
                  height: 74
                  radius: 12
                  color: modelData.enabled ? root.bgCard : root.bgSurface
                  border.color: modelData.enabled ? root.borderActive : root.borderSubtle
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 14

                    // Dynamic Icon Badge
                    Rectangle {
                      Layout.preferredWidth: 46
                      Layout.preferredHeight: 46
                      radius: 12
                      color: modelData.enabled ? root.accentGlow : root.bgElevated
                      border.color: modelData.enabled ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.3) : root.borderSubtle
                      border.width: 1

                      Text {
                        anchors.centerIn: parent
                        text: root.getPluginIcon(modelData.id, modelData.name)
                        color: modelData.enabled ? root.accent : root.fgDim
                        font.family: root.nfFontFamily
                        font.pixelSize: 22
                      }
                    }

                    // Metadata
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 3

                      RowLayout {
                        spacing: 8
                        Text {
                          text: modelData.name || modelData.id
                          color: root.fgMain
                          font.pixelSize: 14
                          font.bold: true
                        }

                        // Kind pills
                        Repeater {
                          model: modelData.kinds || []
                          delegate: Rectangle {
                            required property var modelData
                            Layout.preferredHeight: 20
                            Layout.preferredWidth: kindText.implicitWidth + 12
                            radius: 6
                            color: root.purpleGlow
                            border.color: Qt.rgba(root.purpleTag.r, root.purpleTag.g, root.purpleTag.b, 0.3)
                            border.width: 1

                            Text {
                              id: kindText
                              anchors.centerIn: parent
                              text: modelData === "bar-widget" ? "Widget" : (modelData === "service" ? "Service" : (modelData === "panel" ? "Panel" : modelData))
                              color: root.purpleTag
                              font.pixelSize: 10
                              font.bold: true
                            }
                          }
                        }

                        // Source pill
                        Rectangle {
                          Layout.preferredHeight: 20
                          Layout.preferredWidth: srcText.implicitWidth + 12
                          radius: 6
                          color: modelData.firstParty ? Qt.rgba(255, 255, 255, 0.05) : root.greenGlow
                          border.color: modelData.firstParty ? root.borderSubtle : Qt.rgba(root.greenSuccess.r, root.greenSuccess.g, root.greenSuccess.b, 0.3)
                          border.width: 1

                          Text {
                            id: srcText
                            anchors.centerIn: parent
                            text: modelData.firstParty ? "Core" : "User"
                            color: modelData.firstParty ? root.fgDim : root.greenSuccess
                            font.pixelSize: 10
                            font.bold: true
                          }
                        }
                      }

                      Text {
                        Layout.fillWidth: true
                        text: root.getPluginDescription(modelData)
                        color: root.fgMuted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                      }
                    }

                    // Interactive Controls Row
                    RowLayout {
                      spacing: 8

                      // Bar Pin Button
                      Rectangle {
                        visible: isBarCompatible
                        Layout.preferredHeight: 32
                        Layout.preferredWidth: barBtnText.implicitWidth + 24
                        radius: 8
                        color: inBar ? root.greenGlow : root.bgElevated
                        border.color: inBar ? root.greenSuccess : root.borderSubtle
                        border.width: 1

                        RowLayout {
                          anchors.centerIn: parent
                          spacing: 6
                          Text {
                            text: inBar ? root.nf(root.ic.pin) : root.nf(root.ic.plus)
                            color: inBar ? root.greenSuccess : root.fgMuted
                            font.family: root.nfFontFamily
                            font.pixelSize: 12
                          }
                          Text {
                            id: barBtnText
                            text: inBar ? "In Top Bar" : "Pin to Bar"
                            color: inBar ? root.greenSuccess : root.fgMuted
                            font.pixelSize: 11
                            font.bold: inBar
                          }
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: root.toggleBarPlacement(modelData)
                        }
                      }

                      // Shortcut Keycap Button
                      Rectangle {
                        Layout.preferredHeight: 32
                        Layout.preferredWidth: scBtnText.implicitWidth + 24
                        radius: 8
                        color: shortcut !== "" ? root.amberGlow : root.bgElevated
                        border.color: shortcut !== "" ? root.amberWarn : root.borderSubtle
                        border.width: 1

                        RowLayout {
                          anchors.centerIn: parent
                          spacing: 6
                          Text {
                            text: root.nf(root.ic.keyboard)
                            color: shortcut !== "" ? root.amberWarn : root.fgDim
                            font.family: root.nfFontFamily
                            font.pixelSize: 13
                          }
                          Text {
                            id: scBtnText
                            text: shortcut !== "" ? shortcut : "Shortcut"
                            color: shortcut !== "" ? root.amberWarn : root.fgMuted
                            font.pixelSize: 11
                            font.bold: shortcut !== ""
                          }
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: root.openShortcutDialog(modelData)
                        }
                      }

                      // Delete User Plugin
                      Rectangle {
                        visible: !modelData.firstParty
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 8
                        color: root.redGlow
                        border.color: Qt.rgba(root.redDanger.r, root.redDanger.g, root.redDanger.b, 0.4)
                        border.width: 1

                        Text {
                          anchors.centerIn: parent
                          text: root.nf(root.ic.trash)
                          color: root.redDanger
                          font.family: root.nfFontFamily
                          font.pixelSize: 14
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: root.confirmUninstall(modelData)
                        }
                      }

                      // Active Toggle Switch
                      Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 28
                        radius: 14
                        color: modelData.enabled ? root.accent : root.bgElevated
                        border.color: modelData.enabled ? root.accent : root.borderSubtle
                        border.width: 1

                        Rectangle {
                          width: 22
                          height: 22
                          radius: 11
                          color: "#ffffff"
                          anchors.verticalCenter: parent.verticalCenter
                          x: modelData.enabled ? 23 : 3
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
          }

          // -------------------------------------------------------- TAB 2: MARKETPLACE
          Item {
            ColumnLayout {
              anchors.fill: parent
              spacing: 12

              // Filter & Search Toolbar
              RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Search Box
                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 40
                  radius: 12
                  color: root.bgSurface
                  border.color: root.borderSubtle
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                      text: root.nf(root.ic.globe)
                      color: root.fgDim
                      font.family: root.nfFontFamily
                      font.pixelSize: 14
                    }

                    TextInput {
                      id: marketSearchInput
                      Layout.fillWidth: true
                      text: root.marketSearch
                      color: root.fgMain
                      font.pixelSize: 13
                      selectByMouse: true
                      onTextChanged: root.marketSearch = text

                      Text {
                        text: "Search 1,000+ community extensions from OmarchyPlugins.com..."
                        color: root.fgDim
                        font.pixelSize: 13
                        visible: !marketSearchInput.text
                      }
                    }

                    Text {
                      visible: marketSearchInput.text.length > 0
                      text: root.nf(root.ic.close)
                      color: root.fgDim
                      font.family: root.nfFontFamily
                      font.pixelSize: 13
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.marketSearch = ""
                      }
                    }
                  }
                }

                // Category Chips ScrollView
                ScrollView {
                  Layout.preferredWidth: 460
                  Layout.preferredHeight: 40
                  ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                  ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                  RowLayout {
                    spacing: 6
                    Repeater {
                      model: ["All", "Widgets", "Desktop", "System", "Productivity", "Developer Tools", "Appearance", "Utilities"]
                      delegate: Rectangle {
                        required property var modelData
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: mCatText.implicitWidth + 20
                        radius: 17
                        color: root.marketCategory === modelData ? root.accentGlow : root.bgSurface
                        border.color: root.marketCategory === modelData ? root.accent : root.borderSubtle
                        border.width: 1

                        Text {
                          id: mCatText
                          anchors.centerIn: parent
                          text: modelData
                          color: root.marketCategory === modelData ? root.accent : root.fgMuted
                          font.pixelSize: 12
                          font.bold: root.marketCategory === modelData
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
              }

              // Marketplace Cards List
              ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: root.filteredMarketplace

                delegate: Rectangle {
                  required property var modelData
                  property bool installed: root.isInstalled(modelData.id)

                  width: parent ? parent.width : 0
                  height: 78
                  radius: 12
                  color: installed ? root.bgCard : root.bgSurface
                  border.color: installed ? Qt.rgba(root.greenSuccess.r, root.greenSuccess.g, root.greenSuccess.b, 0.3) : root.borderSubtle
                  border.width: 1

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 14

                    // Initial Badge
                    Rectangle {
                      Layout.preferredWidth: 46
                      Layout.preferredHeight: 46
                      radius: 12
                      color: root.bgElevated
                      border.color: root.borderSubtle
                      border.width: 1

                      Text {
                        anchors.centerIn: parent
                        text: modelData.initials || root.getPluginIcon(modelData.id, modelData.name)
                        color: root.accent
                        font.family: root.nfFontFamily
                        font.pixelSize: modelData.initials ? 16 : 22
                        font.bold: !!modelData.initials
                      }
                    }

                    // Metadata
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 3

                      RowLayout {
                        spacing: 8
                        Text {
                          text: modelData.name || modelData.id
                          color: root.fgMain
                          font.pixelSize: 14
                          font.bold: true
                        }

                        Text {
                          visible: (modelData.stars || 0) > 0
                          text: root.nf(root.ic.star) + " " + modelData.stars
                          color: "#e0af68"
                          font.family: root.nfFontFamily
                          font.pixelSize: 11
                          font.bold: true
                        }

                        Rectangle {
                          visible: modelData.category !== undefined && modelData.category !== ""
                          Layout.preferredHeight: 20
                          Layout.preferredWidth: catPill.implicitWidth + 12
                          radius: 6
                          color: root.purpleGlow
                          border.color: Qt.rgba(root.purpleTag.r, root.purpleTag.g, root.purpleTag.b, 0.3)
                          border.width: 1

                          Text {
                            id: catPill
                            anchors.centerIn: parent
                            text: modelData.category || "Misc"
                            color: root.purpleTag
                            font.pixelSize: 10
                          }
                        }

                        Text {
                          visible: modelData.author !== undefined && modelData.author !== ""
                          text: "by " + modelData.author
                          color: root.fgDim
                          font.pixelSize: 11
                        }
                      }

                      Text {
                        Layout.fillWidth: true
                        text: modelData.description || ""
                        color: root.fgMuted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                      }
                    }

                    // Actions
                    RowLayout {
                      spacing: 8

                      // Repo Link
                      Rectangle {
                        visible: modelData.repo !== undefined && modelData.repo !== ""
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 8
                        color: root.bgElevated
                        border.color: root.borderSubtle
                        border.width: 1

                        Text {
                          anchors.centerIn: parent
                          text: root.nf(root.ic.externalLink)
                          color: root.fgMain
                          font.family: root.nfFontFamily
                          font.pixelSize: 14
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: {
                            if (modelData.repo) {
                              Qt.openUrlExternally(modelData.repo)
                            }
                          }
                        }
                      }

                      // Install / Installed Status Button
                      Rectangle {
                        Layout.preferredHeight: 34
                        Layout.preferredWidth: installed ? 100 : 84
                        radius: 8
                        color: installed ? root.greenGlow : (root.installingId === modelData.id ? root.bgElevated : root.accent)
                        border.color: installed ? root.greenSuccess : "transparent"
                        border.width: installed ? 1 : 0

                        Text {
                          anchors.centerIn: parent
                          text: installed ? root.nf(root.ic.check) + " Installed" : (root.installingId === modelData.id ? "Installing..." : "Install")
                          color: installed ? root.greenSuccess : (root.installingId === modelData.id ? root.fgDim : "#11121d")
                          font.family: root.nfFontFamily
                          font.pixelSize: 11
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
      }

      // ========================================================== MODALS
      // 1. Keyboard Shortcut Dialog Modal
      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        visible: root.shortcutDialogOpen

        MouseArea { anchors.fill: parent; onClicked: root.shortcutDialogOpen = false }

        Rectangle {
          anchors.centerIn: parent
          width: 480
          height: 290
          radius: 16
          color: root.bgSurface
          border.color: root.borderActive
          border.width: 1

          MouseArea { anchors.fill: parent }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            RowLayout {
              spacing: 10
              Text {
                text: root.nf(root.ic.keyboard)
                color: root.amberWarn
                font.family: root.nfFontFamily
                font.pixelSize: 19
              }
              Text {
                text: "Set Keyboard Shortcut"
                color: root.fgMain
                font.pixelSize: 16
                font.bold: true
              }
            }

            Text {
              text: "Configure a global Hyprland keybind for '" + (root.shortcutTargetPlugin ? (root.shortcutTargetPlugin.name || root.shortcutTargetPlugin.id) : "") + "':"
              color: root.fgMuted
              font.pixelSize: 12
            }

            // Key Input Box
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 42
              radius: 10
              color: root.bgBase
              border.color: root.amberWarn
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                TextInput {
                  id: scInputField
                  Layout.fillWidth: true
                  text: root.shortcutInput
                  color: root.fgMain
                  font.pixelSize: 13
                  font.bold: true
                  selectByMouse: true
                  onTextChanged: root.shortcutInput = text

                  Text {
                    text: "e.g. SUPER + ALT + D"
                    color: root.fgDim
                    font.pixelSize: 13
                    visible: !scInputField.text
                  }
                }
              }
            }

            // Quick Modifiers row
            RowLayout {
              spacing: 6
              Text { text: "Add:"; color: root.fgDim; font.pixelSize: 11 }
              Repeater {
                model: ["SUPER + ", "ALT + ", "CTRL + ", "SHIFT + "]
                delegate: Rectangle {
                  required property var modelData
                  Layout.preferredHeight: 26
                  Layout.preferredWidth: qModText.implicitWidth + 14
                  radius: 6
                  color: root.bgElevated
                  border.color: root.borderSubtle
                  border.width: 1

                  Text {
                    id: qModText
                    anchors.centerIn: parent
                    text: modelData
                    color: root.fgMain
                    font.pixelSize: 11
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.shortcutInput.indexOf(modelData) === -1) {
                        root.shortcutInput = modelData + root.shortcutInput
                      }
                    }
                  }
                }
              }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
              Layout.fillWidth: true
              Button {
                text: "Clear Shortcut"
                onClicked: root.clearShortcut()
              }
              Item { Layout.fillWidth: true }
              Button {
                text: "Cancel"
                onClicked: root.shortcutDialogOpen = false
              }
              Button {
                text: "Save & Apply"
                highlighted: true
                onClicked: root.saveShortcut()
              }
            }
          }
        }
      }

      // 2. Bar Section Selector Modal
      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        visible: root.barSectionDialogOpen

        MouseArea { anchors.fill: parent; onClicked: root.barSectionDialogOpen = false }

        Rectangle {
          anchors.centerIn: parent
          width: 440
          height: 230
          radius: 16
          color: root.bgSurface
          border.color: root.borderActive
          border.width: 1

          MouseArea { anchors.fill: parent }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            RowLayout {
              spacing: 8
              Text {
                text: root.nf(root.ic.pin)
                color: root.accent
                font.family: root.nfFontFamily
                font.pixelSize: 17
              }
              Text {
                text: "Pin to Omarchy Top Bar"
                color: root.fgMain
                font.pixelSize: 16
                font.bold: true
              }
            }

            Text {
              text: "Choose which section of the top bar to place '" + (root.barTargetPlugin ? (root.barTargetPlugin.name || root.barTargetPlugin.id) : "") + "':"
              color: root.fgMuted
              font.pixelSize: 12
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 10

              Button {
                Layout.fillWidth: true
                text: root.nf(root.ic.arrowLeft) + " Left"
                font.family: root.nfFontFamily
                onClicked: root.addPluginToBar(root.barTargetPlugin, "left")
              }
              Button {
                Layout.fillWidth: true
                text: "Center"
                onClicked: root.addPluginToBar(root.barTargetPlugin, "center")
              }
              Button {
                Layout.fillWidth: true
                text: "Right " + root.nf(root.ic.arrowRight)
                font.family: root.nfFontFamily
                highlighted: true
                onClicked: root.addPluginToBar(root.barTargetPlugin, "right")
              }
            }

            Item { Layout.fillHeight: true }

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
        color: Qt.rgba(0, 0, 0, 0.8)
        visible: root.urlDialogOpen

        MouseArea { anchors.fill: parent; onClicked: root.urlDialogOpen = false }

        Rectangle {
          anchors.centerIn: parent
          width: 480
          height: 210
          radius: 16
          color: root.bgSurface
          border.color: root.borderActive
          border.width: 1

          MouseArea { anchors.fill: parent }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            Text {
              text: "Install from Git Repository"
              color: root.fgMain
              font.pixelSize: 16
              font.bold: true
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 40
              radius: 10
              color: root.bgBase
              border.color: root.accent
              border.width: 1

              TextInput {
                anchors.fill: parent
                anchors.margins: 10
                text: root.urlInput
                color: root.fgMain
                font.pixelSize: 13
                selectByMouse: true
                onTextChanged: root.urlInput = text
                Text {
                  text: "https://github.com/author/plugin.git"
                  color: root.fgDim
                  font.pixelSize: 13
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
                text: "Install & Enable"
                highlighted: true
                onClicked: root.installFromUrl(root.urlInput)
              }
            }
          }
        }
      }

      // 4. Confirm Uninstall Modal
      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        visible: root.confirmUninstallOpen

        MouseArea { anchors.fill: parent; onClicked: root.confirmUninstallOpen = false }

        Rectangle {
          anchors.centerIn: parent
          width: 420
          height: 180
          radius: 16
          color: root.bgSurface
          border.color: root.redDanger
          border.width: 1

          MouseArea { anchors.fill: parent }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            Text {
              text: "Uninstall Plugin"
              color: root.redDanger
              font.pixelSize: 16
              font.bold: true
            }

            Text {
              text: "Are you sure you want to completely remove '" + (root.pendingUninstallPlugin ? (root.pendingUninstallPlugin.name || root.pendingUninstallPlugin.id) : "") + "'?"
              color: root.fgMain
              font.pixelSize: 12
            }

            RowLayout {
              Layout.fillWidth: true
              Item { Layout.fillWidth: true }
              Button {
                text: "Cancel"
                onClicked: root.confirmUninstallOpen = false
              }
              Button {
                text: "Remove Plugin"
                highlighted: true
                onClicked: root.executeUninstall()
              }
            }
          }
        }
      }

      // 5. Restart Shell Modal
      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.8)
        visible: root.restartDialogOpen

        MouseArea { anchors.fill: parent; onClicked: root.restartDialogOpen = false }

        Rectangle {
          anchors.centerIn: parent
          width: 420
          height: 180
          radius: 16
          color: root.bgSurface
          border.color: root.borderActive
          border.width: 1

          MouseArea { anchors.fill: parent }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            RowLayout {
              spacing: 8
              Text {
                text: root.nf(root.ic.bolt)
                color: root.amberWarn
                font.family: root.nfFontFamily
                font.pixelSize: 17
              }
              Text {
                text: "Restart Quickshell"
                color: root.fgMain
                font.pixelSize: 16
                font.bold: true
              }
            }

            Text {
              text: "Restart the Omarchy desktop shell to reload all widgets and panels?"
              color: root.fgMuted
              font.pixelSize: 12
            }

            RowLayout {
              Layout.fillWidth: true
              Item { Layout.fillWidth: true }
              Button {
                text: "Cancel"
                onClicked: root.restartDialogOpen = false
              }
              Button {
                text: "Restart Shell"
                highlighted: true
                onClicked: root.restartShell()
              }
            }
          }
        }
      }
    }
  }
}
