import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "deomarchy.notification-center"
  ipcTarget: "deomarchy.notification-center"

  implicitWidth: 440
  implicitHeight: 620

  property var anchorItem: null
  property var hostWidget: null

  // Bar-widget mounting injects the shell through `bar`; the shell's own
  // panel loader injects it directly as `shell`. Accept either so the panel
  // works even when this plugin has no bar widget placed.
  property var shell: null
  readonly property var shellRef: root.bar && root.bar.shell ? root.bar.shell : root.shell

  // The notification service lives in another first-party plugin; everything
  // this panel shows flows through it: popupModel for live toasts, the
  // history directory for what has already left the screen.
  readonly property var notifService: {
    var shellObj = root.shellRef
    if (!shellObj) return null
    return shellObj.firstPartyServiceFor("omarchy.notifications")
      || shellObj.serviceFor("omarchy.notifications")
  }
  readonly property int liveCount: notifService ? notifService.popupModel.count : 0
  readonly property bool dndOn: notifService ? notifService.doNotDisturb : false

  // ---------------------------------------------------------------- history

  // Newest-first parsed entries straight from the service's history dir.
  // The service owns the files; this panel only reads them.
  property var historyEntries: []

  Process {
    id: historyReader
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var rows = []
        var lines = String(text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim()
          if (!line) continue
          try {
            var value = JSON.parse(line)
            if (value && typeof value === "object") rows.push(value)
          } catch (e) {
            // Torn line — skip it, keep the rest.
          }
        }
        rows.sort(function(a, b) { return (b.timestamp || 0) - (a.timestamp || 0) })
        root.historyEntries = rows
      }
    }
  }

  function loadHistory() {
    if (!notifService) return
    historyReader.command = ["bash", "-c",
      "awk 1 \"$1\"/*.json 2>/dev/null || true", "--", notifService.historyDir]
    historyReader.running = true
  }

  onOpenedChanged: if (opened) loadHistory()
  Component.onCompleted: loadHistory()

  // A toast leaving the screen lands in history moments later; poll lightly
  // while open instead of wiring into the service's file queue.
  Timer {
    interval: 5000
    repeat: true
    running: root.opened
    onTriggered: root.loadHistory()
  }

  Connections {
    target: root.notifService ? root.notifService.popupModel : null
    ignoreUnknownSignals: true
    function onCountChanged() { Qt.callLater(root.loadHistory) }
  }

  // ---------------------------------------------------------------- helpers

  readonly property string nfFontFamily: "JetBrainsMono Nerd Font"
  function nf(code) { return String.fromCodePoint(code) }
  readonly property var ic: ({
    bell: 0xF009A,          // md-bell-outline
    bellRing: 0xF009D,      // md-bell-ring
    bellOff: 0xF009C,       // md-bell-off
    close: 0xF0156,         // md-close
    deleteAll: 0xF01B4,     // md-delete-sweep
    clock: 0xF0954          // md-clock-time-four-outline
  })

  function relativeTime(ts) {
    var delta = Math.max(0, Date.now() - (ts || 0))
    var minutes = Math.floor(delta / 60000)
    if (minutes < 1) return "now"
    if (minutes < 60) return minutes + "m"
    var hours = Math.floor(minutes / 60)
    if (hours < 24) return hours + "h"
    return Math.floor(hours / 24) + "d"
  }

  function urgencyColor(urgency) {
    return urgency === NotificationUrgency.Critical ? Color.urgent : "transparent"
  }

  function rowFont() {
    return root.bar && root.bar.fontFamily ? root.bar.fontFamily : nfFontFamily
  }

  // ---------------------------------------------------------------- layout

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(8)

    // Header: title, DND toggle, clear-history.
    RowLayout {
      Layout.fillWidth: true
      Layout.margins: Style.space(10)
      spacing: Style.space(8)

      Text {
        text: nf(root.dndOn ? ic.bellOff : (root.liveCount > 0 ? ic.bellRing : ic.bell))
        font.family: nfFontFamily
        font.pixelSize: 18
        color: root.dndOn ? Color.muted : Color.accent
      }

      Text {
        Layout.fillWidth: true
        text: root.dndOn ? "Notifications (muted)" : "Notifications"
        color: root.barForeground
        font.family: rowFont()
        font.pixelSize: 14
        font.bold: true
        elide: Text.ElideRight
      }

      Button {
        id: dndButton
        checkable: true
        checked: root.dndOn
        text: checked ? "DND on" : "DND off"
        font.family: rowFont()
        font.pixelSize: 11

        onClicked: if (root.notifService) root.notifService.setDoNotDisturb(checked)
      }

      Button {
        id: clearButton
        enabled: root.historyEntries.length > 0
        font.family: nfFontFamily
        font.pixelSize: 13
        text: nf(ic.deleteAll)
        ToolTip.visible: hovered
        ToolTip.text: "Clear history"

        onClicked: {
          if (!root.notifService) return
          root.notifService.clearHistory()
          Qt.callLater(root.loadHistory)
        }
      }
    }

    // Body: live toasts first, then history.
    Flickable {
      id: scroll
      Layout.fillWidth: true
      Layout.fillHeight: true
      contentWidth: width
      contentHeight: bodyColumn.implicitHeight + Style.space(20)
      clip: true
      ScrollBar.vertical: ScrollBar {}

      ColumnLayout {
        id: bodyColumn
        width: scroll.width
        spacing: Style.space(4)

        Text {
          visible: root.liveCount > 0
          leftPadding: Style.space(10)
          text: "ON SCREEN"
          color: Color.muted
          font.family: rowFont()
          font.pixelSize: 9
          font.bold: true
          font.letterSpacing: 1
        }

        Repeater {
          model: root.notifService ? root.notifService.popupModel : null

          delegate: RowLayout {
            id: liveRow
            required property int index
            required property string app
            required property string summary
            required property string body
            required property string image
            required property string glyph
            required property int urgency
            required property double timestamp

            Layout.fillWidth: true
            Layout.leftMargin: Style.space(6)
            Layout.rightMargin: Style.space(6)
            spacing: Style.space(8)

            Rectangle {
              width: 3
              implicitHeight: liveRowCard.implicitHeight
              radius: 1
              color: root.urgencyColor(liveRow.urgency)
            }

            Rectangle {
              id: liveRowCard
              Layout.fillWidth: true
              implicitHeight: liveRowTexts.implicitHeight + Style.space(12)
              radius: 8
              color: liveRowMa.containsMouse ? Color.selection : "transparent"

              MouseArea {
                id: liveRowMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.notifService) root.notifService.invokePopupDefault(liveRow.index)
              }

              ColumnLayout {
                id: liveRowTexts
                anchors.left: parent.left
                anchors.right: dismissButton.left
                anchors.rightMargin: Style.space(4)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                  Layout.fillWidth: true
                  text: liveRow.summary || "(no title)"
                  color: root.barForeground
                  font.family: rowFont()
                  font.pixelSize: 12
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  Layout.fillWidth: true
                  visible: liveRow.body !== ""
                  text: liveRow.body
                  color: root.barForeground
                  opacity: 0.75
                  font.family: rowFont()
                  font.pixelSize: 11
                  wrapMode: Text.WordWrap
                  maximumLineCount: 3
                  elide: Text.ElideRight
                }
                Text {
                  Layout.fillWidth: true
                  text: (liveRow.app || "") + "  ·  " + root.relativeTime(liveRow.timestamp)
                  color: Color.muted
                  font.family: rowFont()
                  font.pixelSize: 9
                  elide: Text.ElideRight
                }
              }

              Text {
                id: dismissButton
                anchors.right: parent.right
                anchors.rightMargin: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                text: nf(ic.close)
                font.family: nfFontFamily
                font.pixelSize: 13
                color: dismissMa.containsMouse ? root.barForeground : Color.muted

                MouseArea {
                  id: dismissMa
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: if (root.notifService) root.notifService.dismissPopup(liveRow.index)
                }
              }
            }
          }
        }

        Item { Layout.preferredHeight: root.liveCount > 0 ? Style.space(8) : 0 }

        Text {
          visible: root.historyEntries.length > 0
          leftPadding: Style.space(10)
          text: "HISTORY"
          color: Color.muted
          font.family: rowFont()
          font.pixelSize: 9
          font.bold: true
          font.letterSpacing: 1
        }

        Repeater {
          model: root.historyEntries

          delegate: RowLayout {
            id: histRow
            required property int index
            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: Style.space(6)
            Layout.rightMargin: Style.space(6)
            spacing: Style.space(8)

            Rectangle {
              width: 3
              implicitHeight: histCard.implicitHeight
              radius: 1
              color: root.urgencyColor(histRow.modelData.urgency)
            }

            Rectangle {
              id: histCard
              Layout.fillWidth: true
              implicitHeight: histTexts.implicitHeight + Style.space(12)
              radius: 8
              color: histMa.containsMouse ? Color.selection : "transparent"

              MouseArea {
                id: histMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: histRow.modelData.exec ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                  // Persisted toasts carry their omarchy-action command; fire it
                  // detached exactly like the live-popup path does.
                  var cmd = String(histRow.modelData.exec || "")
                  if (cmd) Util.execDetached(cmd)
                }
              }

              ColumnLayout {
                id: histTexts
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: Style.space(8)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                  Layout.fillWidth: true
                  text: histRow.modelData.summary || "(no title)"
                  color: root.barForeground
                  opacity: 0.9
                  font.family: rowFont()
                  font.pixelSize: 12
                  elide: Text.ElideRight
                }
                Text {
                  Layout.fillWidth: true
                  visible: !!histRow.modelData.body
                  text: histRow.modelData.body
                  color: root.barForeground
                  opacity: 0.6
                  font.family: rowFont()
                  font.pixelSize: 11
                  maximumLineCount: 2
                  wrapMode: Text.WordWrap
                  elide: Text.ElideRight
                }
                Text {
                  Layout.fillWidth: true
                  text: (histRow.modelData.app || "") + "  ·  " + root.relativeTime(histRow.modelData.timestamp)
                    + (histRow.modelData.exec ? "  ·  click to run action" : "")
                  color: Color.muted
                  font.family: rowFont()
                  font.pixelSize: 9
                  elide: Text.ElideRight
                }
              }
            }
          }
        }

        // Empty state — shown only when there is truly nothing anywhere.
        ColumnLayout {
          visible: root.liveCount === 0 && root.historyEntries.length === 0
          Layout.alignment: Qt.AlignHCenter
          Layout.topMargin: Style.space(48)
          spacing: Style.space(10)

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: nf(ic.bell)
            font.family: nfFontFamily
            font.pixelSize: 32
            color: Color.muted
            opacity: 0.5
          }
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "No notifications"
            color: Color.muted
            font.family: rowFont()
            font.pixelSize: 12
          }
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "SUPER + ALT + N opens this panel"
            color: Color.muted
            opacity: 0.7
            font.family: rowFont()
            font.pixelSize: 10
          }
        }
      }
    }
  }
}
