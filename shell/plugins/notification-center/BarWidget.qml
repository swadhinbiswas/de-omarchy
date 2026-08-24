import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "deomarchy.notification-center"

  // The notification service is a separate first-party plugin; reach it
  // through the shell's service map so the bell reacts to live toasts.
  readonly property var notifService: root.bar && root.bar.shell
    ? (root.bar.shell.firstPartyServiceFor("omarchy.notifications")
       || root.bar.shell.serviceFor("omarchy.notifications"))
    : null
  readonly property int liveCount: notifService ? notifService.popupModel.count : 0
  readonly property bool dndOn: notifService ? notifService.doNotDisturb : false

  readonly property bool opened: panelItem ? panelItem.opened === true : false

  function open() { if (panelItem) panelItem.open() }
  function close() { if (panelItem) panelItem.close() }
  function togglePanel() { if (panelItem) panelItem.toggle() }

  readonly property bool popoutSwitchClosing: panelItem ? panelItem.popoutSwitchClosing === true : false
  function closeForPopoutSwitch() { if (panelItem) panelItem.closeForPopoutSwitch() }

  property var panelItem: null

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    panelItem = target
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth + (badge.visible ? badge.width : 0)
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "deomarchy.notification-center"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  BarIconButton {
    id: button
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    bar: root.bar
    // md-bell / md-bell-ring / md-bell-off from JetBrainsMono Nerd Font — the
    // family the bar already renders with, matching the other widgets.
    text: String.fromCodePoint(
      root.dndOn ? 0xF009C
      : (root.liveCount > 0 ? 0xF009D : 0xF009A))
    tooltipText: {
      if (root.dndOn) return "Notifications muted (DND)"
      if (root.liveCount > 0) return root.liveCount + " notification" + (root.liveCount === 1 ? "" : "s")
      return "Notification Center"
    }

    onPressed: function(b) {
      if (b === Qt.LeftButton) root.togglePanel()
      else if (b === Qt.RightButton && root.notifService)
        root.notifService.setDoNotDisturb(!root.notifService.doNotDisturb)
    }
  }

  // Unread pill beside the bell while live toasts are up.
  Rectangle {
    id: badge
    visible: root.liveCount > 0 && !root.dndOn
    anchors.left: button.right
    anchors.leftMargin: -2
    anchors.top: parent.top
    anchors.topMargin: 2
    implicitWidth: Math.max(14, countLabel.implicitWidth + 6)
    implicitHeight: 14
    radius: height / 2
    color: Color.accent

    TextMetrics {
      id: countText
      text: root.liveCount > 9 ? "9+" : String(root.liveCount)
    }

    Text {
      id: countLabel
      anchors.centerIn: parent
      text: countText.text
      color: Color.background
      font.family: root.bar && root.bar.fontFamily ? root.bar.fontFamily : "JetBrainsMono Nerd Font"
      font.pixelSize: 8
      font.bold: true
    }
  }
}
