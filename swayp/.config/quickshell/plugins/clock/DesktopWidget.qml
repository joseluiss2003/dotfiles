import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

Item {
  id: root

  property real widgetWidth: 520
  property real widgetHeight: 190
  property date displayDate: clock.date

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.displayDate = date
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: clockWindow
      required property var modelData

      screen: modelData
      implicitWidth: root.widgetWidth
      implicitHeight: root.widgetHeight

      anchors.right: true
      anchors.bottom: true
      margins.right: Style.space(24)
      margins.bottom: Style.space(28) + Style.space(190) + Style.space(10)

      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Bottom

      BorderSurface {
        anchors.fill: parent
        color: Util.alpha(Color.background, 0.92)
        borderSpec: Border.flat(Util.alpha(Color.accent, 0.68), 1)

        Text {
          id: timeText
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: Style.space(30)
          text: Qt.formatDateTime(root.displayDate, "HH:mm")
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(3.8)
          font.weight: Font.DemiBold
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: timeText.bottom
          anchors.topMargin: Style.space(2)
          text: Qt.formatDateTime(root.displayDate, "dddd, MMMM d")
          color: Util.alpha(Color.foreground, 0.72)
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.9)
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
