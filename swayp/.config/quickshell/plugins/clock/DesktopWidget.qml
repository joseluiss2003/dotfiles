import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

Item {
  id: root

  property real widgetWidth: 520
  property real widgetHeight: 88
  property date displayDate: clock.date

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
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
          id: header
          x: Style.space(14)
          y: Style.space(9)
          text: "> clock"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.78)
          font.weight: Font.DemiBold
        }

        Text {
          x: width - implicitWidth - Style.space(14)
          y: header.y
          text: "system"
          color: Util.alpha(Color.muted, 0.62)
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.72)
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: Style.space(14)
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(9)
          text: Qt.formatDateTime(root.displayDate, "HH:mm:ss")
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(1.55)
          font.weight: Font.DemiBold
        }

        Text {
          anchors.right: parent.right
          anchors.rightMargin: Style.space(14)
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(12)
          text: Qt.formatDateTime(root.displayDate, "ddd dd MMM yyyy").toUpperCase()
          color: Util.alpha(Color.muted, 0.82)
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.76)
        }
      }
    }
  }
}
