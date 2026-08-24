import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root

  // ---------------------------------------------------------------- Visual Design System
  // Matches the Plugin Manager window so the two feel like one suite.
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

  // ---------------------------------------------------------------- Iconography
  //
  // Nerd Font glyph codepoints (the family the bar and terminal render),
  // stored as ints because most live beyond the BMP.
  readonly property string nfFontFamily: "JetBrainsMono Nerd Font"
  function nf(code) { return String.fromCodePoint(code) }

  readonly property var ic: ({
    keyboard: 0xF097B,       // md-keyboard_outline  brand / hardware keys
    magnify: 0xF0349,        // md-magnify           search
    close: 0xF0156,          // md-close             clear search
    refresh: 0xF0450,        // md-refresh           reload data
    chevronRight: 0xF0142,   // md-chevron_right     row affordance
    dotsHorizontal: 0xF01D8, // md-dots_horizontal   general category
    rocket: 0xF0463,         // md-rocket            menus & launchers
    windowOpen: 0xF05B1,     // md-window_open       windows & tiling
    viewGrid: 0xF0570,       // md-view_grid         workspaces & monitors
    power: 0xF0425,          // md-power             system & power
    cameraOutline: 0xF0D5D,  // md-camera_outline    capture & recording
    volumeHigh: 0xF057E,     // md-volume_high       audio & media
    brightness: 0xF00DF,     // md-brightness_6      display & brightness
    wifi: 0xF05A9,           // md-wifi              network & devices
    bell: 0xF009A,           // md-bell              clipboard & notifications
    dockWindow: 0xF10AC,     // md-dock_window       shell & panels
    alertCircle: 0xF05D6     // md-alert_circle_outline load failure
  })

  // ---------------------------------------------------------------- Categories
  //
  // Ordered; first pattern hit wins. Action text drives placement so the
  // grouping survives wording changes in the bind sources.
  readonly property var categories: [
    { id: "launchers", label: "Menus & Launchers", icon: root.ic.rocket,
      re: /(menu|launcher|apps? list|picker|actions menu|app launcher)/ },
    { id: "capture", label: "Capture & Recording", icon: root.ic.cameraOutline,
      re: /(screenshot|screenrecording|capture|record|webcam|color picker|ocr|share)/ },
    { id: "audio", label: "Audio & Media", icon: root.ic.volumeHigh,
      re: /(audio|volume|mic mute|playerctl|media|music|cmus|mute mic|play\/pause|track)/ },
    { id: "display", label: "Display & Brightness", icon: root.ic.brightness,
      re: /(brightness|laptop display|display mirroring|^display$|toggle display)/ },
    { id: "network", label: "Network & Devices", icon: root.ic.wifi,
      re: /(wifi|bluetooth|network|tailscale|airplane)/ },
    { id: "clipboard", label: "Clipboard & Notifications", icon: root.ic.bell,
      re: /(clipboard|notification|emoji|reminder|silenc)/ },
    { id: "windows", label: "Windows & Tiling", icon: root.ic.windowOpen,
      re: /(window|tiling|tile|float|fullscreen|maximi|split|swap|pseudo|pop out|pin out|group|resize|expand|shrink|aspect|window width|drag|focus on|cycle)/ },
    { id: "workspaces", label: "Workspaces & Monitors", icon: root.ic.viewGrid,
      re: /(workspace|scratchpad|monitor move|to (left|right|up|down) monitor|next monitor|scroll active)/ },
    { id: "system", label: "System & Power", icon: root.ic.power,
      re: /(lock|logout|reboot|shutdown|power menu|suspend|session|reload|restart|exit|zoom|show time|battery remaining|weather toggle|lid)/ },
    { id: "shell", label: "Shell & Panels", icon: root.ic.dockWindow,
      re: /(panel|top bar|bar$|dashboard|sidebar|cheat|keybind|plugin|theme|wallpaper|background switcher|calculator|activity|agent|utilities|nexus|tmux|herdr)/ }
  ]

  function categorize(action, keys) {
    var a = String(action || "").toLowerCase()
    for (var i = 0; i < root.categories.length; i++) {
      if (root.categories[i].re.test(a)) return root.categories[i].id
    }
    var k = String(keys || "")
    if (k.indexOf("XF86") === 0 || k.indexOf("switch:") === 0 || k.indexOf("mouse") === 0)
      return "hardware"
    return "general"
  }

  function categoryMeta(id) {
    if (id === "hardware")
      return { id: id, label: "Hardware Keys", icon: root.ic.keyboard }
    if (id === "general")
      return { id: id, label: "General", icon: root.ic.dotsHorizontal }
    for (var i = 0; i < root.categories.length; i++)
      if (root.categories[i].id === id) return root.categories[i]
    return { id: "general", label: "General", icon: root.ic.dotsHorizontal }
  }

  // ---------------------------------------------------------------- State
  property var allBindings: []
  property string searchText: ""
  property string activeCategory: "all"
  property bool loading: true
  property bool loadFailed: false

  // Pretty names for keys the engine leaves symbolic.
  function prettyKey(token) {
    var map = {
      MINUS: "-", EQUAL: "=", COMMA: ",", PERIOD: ".", SLASH: "/",
      GRAVE: "`", PRINT: "PrtSc", RETURN: "Enter", ESCAPE: "Esc",
      BACKSPACE: "Bksp", DELETE: "Del", mouse_up: "Wheel Up",
      mouse_down: "Wheel Down", SUPER_L: "SUPER"
    }
    var t = String(token || "")
    if (map[t] !== undefined) return map[t]
    if (t.indexOf("mouse:") === 0) {
      var b = { "272": "Click L", "273": "Click R", "274": "Click M" }
      return b[t.substring(6)] || t
    }
    if (t.indexOf("XF86") === 0) return t.substring(5).replace(/_/g, " ")
    if (t === "LEFT") return "\u2190"
    if (t === "RIGHT") return "\u2192"
    if (t === "UP") return "\u2191"
    if (t === "DOWN") return "\u2193"
    return t
  }

  function isModifier(token) {
    return token === "SUPER" || token === "SHIFT" || token === "ALT" || token === "CTRL"
  }

  // "SUPER SHIFT CTRL + MINUS" → modifier chips + one key chip.
  function keyParts(combo) {
    var groups = String(combo || "").split(" + ")
    var mods = []
    for (var i = 0; i < groups.length - 1; i++) {
      var toks = groups[i].split(" ").filter(function(t) { return t !== "" })
      mods = mods.concat(toks)
    }
    return { mods: mods, key: groups[groups.length - 1] || "" }
  }

  function applyFilter() {
    var q = root.searchText.toLowerCase().trim()
    var res = []
    for (var i = 0; i < root.allBindings.length; i++) {
      var b = root.allBindings[i]
      if (root.activeCategory !== "all" && b.category !== root.activeCategory) continue
      if (q !== "" && b.action.toLowerCase().indexOf(q) === -1 && b.keys.toLowerCase().indexOf(q) === -1) continue
      res.push(b)
    }
    root.filteredBindings = res
  }

  property var filteredBindings: []

  onSearchTextChanged: root.applyFilter()
  onActiveCategoryChanged: root.applyFilter()

  function categoryCount(id) {
    var n = 0
    for (var i = 0; i < root.allBindings.length; i++)
      if (root.allBindings[i].category === id) n++
    return n
  }

  Component.onCompleted: root.loadBindings()

  function loadBindings() {
    root.loading = true
    root.loadFailed = false
    var om = Quickshell.env("OMARCHY_PATH") || "/usr/share/de-omarchy"
    bindsProc.command = ["bash", "-c",
      "omarchy-menu-keybindings --print 2>/dev/null || " + om + "/bin/omarchy-menu-keybindings --print 2>/dev/null"]
    bindsProc.running = true
  }

  Process {
    id: bindsProc
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var list = []
        var lines = String(text).split("\n")
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i]
          if (!line.trim()) continue
          var tabAt = line.indexOf("\t")
          var head = tabAt === -1 ? line : line.substring(0, tabAt)
          var rest = tabAt === -1 ? "" : line.substring(tabAt + 1)
          var arrowAt = head.indexOf(" \u2192 ")
          if (arrowAt === -1) arrowAt = head.indexOf(" -> ")
          if (arrowAt === -1) continue
          var sepLen = head.charAt(arrowAt + 1) === "\u2192" ? 3 : 4
          var keys = head.substring(0, arrowAt).replace(/\s+/g, " ").trim()
          var action = head.substring(arrowAt + sepLen).trim()
          if (!keys || !action) continue
          var restParts = rest.split("\t")
          list.push({
            keys: keys,
            action: action,
            dispatcher: restParts[0] || "",
            arg: restParts.slice(1).join("\t").trim(),
            category: root.categorize(action, keys.split(" + ").pop())
          })
        }
        root.allBindings = list
        root.loading = false
        root.loadFailed = list.length === 0
        root.applyFilter()
      }
    }
  }

  // ---------------------------------------------------------------- Main Window
  Window {
    id: win
    title: "Omarchy Keybindings"
    visible: true
    width: 1060
    height: 720
    minimumWidth: 900
    minimumHeight: 600
    color: root.bgBase

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) Qt.quit()
    }

    Rectangle { anchors.fill: parent; color: root.bgBase }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 14

      // ======================================================= Header
      RowLayout {
        Layout.fillWidth: true
        spacing: 16

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
              text: root.nf(root.ic.keyboard)
              color: root.accent
              font.family: root.nfFontFamily
              font.pixelSize: 22
            }
          }
          ColumnLayout {
            spacing: 2
            Text {
              text: "Keybindings"
              color: root.fgMain
              font.pixelSize: 18
              font.bold: true
            }
            Text {
              text: "Every active Hyprland binding on this system"
              color: root.fgMuted
              font.pixelSize: 11
            }
          }
        }

        Item { Layout.fillWidth: true }

        // Search box
        Rectangle {
          Layout.preferredWidth: 340
          Layout.preferredHeight: 38
          radius: 19
          color: root.bgSurface
          border.color: searchInput.activeFocus ? root.accent : root.borderSubtle
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 8

            Text {
              text: root.nf(root.ic.magnify)
              color: root.fgDim
              font.family: root.nfFontFamily
              font.pixelSize: 14
            }

            TextInput {
              id: searchInput
              Layout.fillWidth: true
              text: root.searchText
              color: root.fgMain
              font.pixelSize: 13
              selectByMouse: true
              focus: true
              onTextChanged: root.searchText = text
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                  if (root.searchText !== "") root.searchText = ""
                  else Qt.quit()
                  event.accepted = true
                }
              }

              Text {
                text: "Search actions or keys...   /  to focus"
                color: root.fgDim
                font.pixelSize: 13
                visible: !searchInput.text
              }
            }

            Text {
              visible: searchInput.text.length > 0
              text: root.nf(root.ic.close)
              color: root.fgDim
              font.family: root.nfFontFamily
              font.pixelSize: 13

              MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.searchText = ""
              }
            }
          }
        }

        // Refresh
        Rectangle {
          Layout.preferredWidth: 38
          Layout.preferredHeight: 38
          radius: 10
          color: refreshArea.pressed ? root.bgElevated : root.bgSurface
          border.color: root.borderSubtle
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: root.nf(root.ic.refresh)
            color: root.fgMuted
            font.family: root.nfFontFamily
            font.pixelSize: 15
          }

          MouseArea {
            id: refreshArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.loadBindings()
          }
        }
      }

      // ======================================================= Body
      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 14

        // -------- Sidebar
        Rectangle {
          Layout.preferredWidth: 232
          Layout.fillHeight: true
          radius: 14
          color: root.bgSurface
          border.color: root.borderSubtle
          border.width: 1

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            // All
            Rectangle {
              id: allChip
              Layout.fillWidth: true
              Layout.preferredHeight: 34
              radius: 9
              color: root.activeCategory === "all" ? root.accentGlow : "transparent"
              border.color: root.activeCategory === "all" ? root.accent : "transparent"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                  text: root.nf(root.ic.keyboard)
                  color: root.activeCategory === "all" ? root.accent : root.fgDim
                  font.family: root.nfFontFamily
                  font.pixelSize: 14
                }
                Text {
                  Layout.fillWidth: true
                  text: "All bindings"
                  color: root.activeCategory === "all" ? root.fgMain : root.fgMuted
                  font.pixelSize: 12
                  font.bold: root.activeCategory === "all"
                }
                Rectangle {
                  Layout.preferredHeight: 18
                  Layout.preferredWidth: allCount.implicitWidth + 10
                  radius: 9
                  color: root.activeCategory === "all" ? root.accent : root.bgElevated
                  Text {
                    id: allCount
                    anchors.centerIn: parent
                    text: root.allBindings.length
                    color: root.activeCategory === "all" ? "#11121d" : root.fgMuted
                    font.pixelSize: 10
                    font.bold: true
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activeCategory = "all"
              }
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 1
              Layout.topMargin: 4
              Layout.bottomMargin: 4
              color: root.borderSubtle
            }

            // Category list
            ListView {
              id: catList
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              spacing: 2
              model: {
                var ids = []
                for (var i = 0; i < root.categories.length; i++) ids.push(root.categories[i].id)
                ids.push("hardware")
                ids.push("general")
                var out = []
                for (var j = 0; j < ids.length; j++) {
                  if (root.categoryCount(ids[j]) > 0) out.push(ids[j])
                }
                return out
              }
              delegate: Rectangle {
                required property var modelData
                readonly property var meta: root.categoryMeta(modelData)
                readonly property bool selected: root.activeCategory === modelData
                width: catList.width
                height: 32
                radius: 9
                color: selected ? root.accentGlow : (catHover.hovered ? root.bgCard : "transparent")
                border.color: selected ? root.accent : "transparent"
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  anchors.rightMargin: 12
                  spacing: 10

                  Text {
                    text: root.nf(meta.icon)
                    color: selected ? root.accent : root.fgDim
                    font.family: root.nfFontFamily
                    font.pixelSize: 13
                  }
                  Text {
                    Layout.fillWidth: true
                    text: meta.label
                    elide: Text.ElideRight
                    color: selected ? root.fgMain : root.fgMuted
                    font.pixelSize: 12
                    font.bold: selected
                  }
                  Text {
                    text: root.categoryCount(modelData)
                    color: selected ? root.accent : root.fgDim
                    font.pixelSize: 10
                    font.bold: selected
                  }
                }

                HoverHandler { id: catHover }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.activeCategory = modelData
                }
              }
            }
          }
        }

        // -------- Binding list
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 8

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: "transparent"

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 6
              anchors.rightMargin: 6

              Text {
                text: root.activeCategory === "all"
                  ? "All bindings"
                  : root.categoryMeta(root.activeCategory).label
                color: root.fgMain
                font.pixelSize: 13
                font.bold: true
              }
              Item { Layout.fillWidth: true }
              Text {
                text: root.filteredBindings.length + " shown"
                color: root.fgDim
                font.pixelSize: 11
              }
            }
          }

          // Loading / empty states
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.loading || root.loadFailed || root.filteredBindings.length === 0

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 12

              Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.loading
                  ? root.nf(root.ic.refresh)
                  : root.nf(root.alertCircle)
                color: root.fgDim
                font.family: root.nfFontFamily
                font.pixelSize: 30
              }
              Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.loading
                  ? "Reading bindings from Hyprland..."
                  : (root.loadFailed
                      ? "Could not read bindings.\nIs hyprctl available and is the shell inside a Hyprland session?"
                      : "No bindings match your search.")
                color: root.fgMuted
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
              }
            }
          }

          ListView {
            id: bindList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            visible: !root.loading && !root.loadFailed
            model: root.filteredBindings

            ScrollBar.vertical: ScrollBar {
              policy: ScrollBar.AsNeeded
            }

            delegate: Rectangle {
              required property var modelData
              readonly property var parts: root.keyParts(modelData.keys)

              width: bindList.width
              implicitHeight: rowCol.implicitHeight + 24
              height: implicitHeight
              radius: 12
              color: rowHover.hovered ? root.bgCardHover : root.bgCard
              border.color: rowHover.hovered ? root.borderActive : root.borderSubtle
              border.width: 1

              RowLayout {
                id: rowCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 14

                // Keycaps — capped so long modifier chains never squeeze the
                // action column.
                RowLayout {
                  Layout.preferredWidth: 286
                  Layout.maximumWidth: 286
                  Layout.alignment: Qt.AlignVCenter
                  spacing: 4

                  Repeater {
                    model: parts.mods
                    delegate: RowLayout {
                      required property var modelData
                      spacing: 4
                      Rectangle {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: modCap.implicitWidth + 14
                        radius: 6
                        color: root.accentGlow
                        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)
                        border.width: 1
                        Text {
                          id: modCap
                          anchors.centerIn: parent
                          text: modelData
                          color: root.accent
                          font.family: root.nfFontFamily
                          font.pixelSize: 10
                          font.bold: true
                        }
                      }
                      Text {
                        visible: index === parts.mods.length - 1
                        text: "+"
                        color: root.fgDim
                        font.pixelSize: 11
                      }
                    }
                  }

                  Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: keyCap.implicitWidth + 16
                    radius: 7
                    color: root.bgElevated
                    border.color: root.borderActive
                    border.width: 1
                    Text {
                      id: keyCap
                      anchors.centerIn: parent
                      text: root.prettyKey(parts.key)
                      color: root.fgMain
                      font.family: root.nfFontFamily
                      font.pixelSize: 11
                      font.bold: true
                    }
                  }

                  Item { Layout.fillWidth: true }
                }

                // Action
                ColumnLayout {
                  Layout.fillWidth: true
                  Layout.minimumWidth: 180
                  Layout.alignment: Qt.AlignVCenter
                  spacing: 2

                  Text {
                    Layout.fillWidth: true
                    text: modelData.action
                    color: root.fgMain
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    maximumLineCount: 1
                  }
                  Text {
                    Layout.fillWidth: true
                    visible: modelData.dispatcher === "exec" && modelData.arg !== ""
                    text: modelData.arg
                    color: root.fgDim
                    font.family: root.nfFontFamily
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                  }
                }

                Text {
                  text: root.nf(root.ic.chevronRight)
                  color: root.fgDim
                  font.family: root.nfFontFamily
                  font.pixelSize: 13
                  opacity: rowHover.hovered ? 1 : 0.35
                }
              }

              HoverHandler { id: rowHover }
            }
          }
        }
      }

      // ======================================================= Footer
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        color: "transparent"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 6
          anchors.rightMargin: 6

          Text {
            text: root.allBindings.length + " bindings \u00B7 grouped by action"
            color: root.fgDim
            font.pixelSize: 11
          }
          Item { Layout.fillWidth: true }
          Text {
            text: "/ search  \u00B7  Esc close"
            color: root.fgDim
            font.pixelSize: 11
          }
        }
      }
    }
  }
}
