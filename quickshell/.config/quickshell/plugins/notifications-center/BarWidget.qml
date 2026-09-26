import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Compact notification entry for the bar. The panel remains the full
// notification-center surface; this widget only exposes its live count and
// opens/toggles the center.
BarWidget {
  id: root

  moduleName: "omarchy.notification-center"

  readonly property var notificationService:
    bar && bar.shell && typeof bar.shell.firstPartyServiceFor === "function"
      ? bar.shell.firstPartyServiceFor("omarchy.notifications")
      : null

  readonly property int notificationCount:
    notificationService && notificationService.popupModel
      ? notificationService.popupModel.count
      : 0

  readonly property string bellGlyph:
    notificationService && notificationService.doNotDisturb
      ? "󰂛"
      : "󰂚"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function toggleCenter() {
    if (!bar || !bar.shell) return
    if (typeof bar.shell.toggle === "function")
      bar.shell.toggle("omarchy.notification-center", "{}")
    else if (typeof bar.shell.summon === "function")
      bar.shell.summon("omarchy.notification-center", "{}")
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.bellGlyph
    fontFamily: root.bar.fontFamily
    foreground: root.bar.barForeground
    activeColor: Color.accent
    hoverColor: Color.accent
    tooltipText: root.notificationCount > 0
      ? root.notificationCount + (root.notificationCount === 1 ? " notification" : " notifications")
      : "Notifications"

    onPressed: function(b) {
      if (b === Qt.LeftButton)
        root.toggleCenter()
    }

    Text {
      visible: root.notificationCount > 0
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: Style.space(2)
      anchors.topMargin: Style.space(2)
      text: root.notificationCount > 9 ? "9+" : String(root.notificationCount)
      color: Color.accent
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
  }
}
