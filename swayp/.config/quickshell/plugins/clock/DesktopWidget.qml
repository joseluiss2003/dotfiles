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
          x: parent.width - implicitWidth - Style.space(14)
          y: header.y
          text: "time"
          color: Util.alpha(Color.muted, 0.62)
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.72)
        }

        Item {
          id: clockDisplay
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          width: 360
          height: 84

          property string value: Qt.formatDateTime(root.displayDate, "HH:mm")
          property var glyphs: ({
            "0": ["11111","10001","10011","10101","11001","10001","11111"],
            "1": ["00100","01100","00100","00100","00100","00100","01110"],
            "2": ["11110","00001","00001","01110","10000","10000","11111"],
            "3": ["11110","00001","00001","01110","00001","00001","11110"],
            "4": ["10010","10010","10010","11111","00010","00010","00010"],
            "5": ["11111","10000","10000","11110","00001","00001","11110"],
            "6": ["01110","10000","10000","11110","10001","10001","01110"],
            "7": ["11111","00001","00010","00100","01000","01000","01000"],
            "8": ["01110","10001","10001","01110","10001","10001","01110"],
            "9": ["01110","10001","10001","01111","00001","00001","01110"]
          })

          Row {
            anchors.centerIn: parent
            spacing: Style.space(8)

            Repeater {
              model: clockDisplay.value.length

              delegate: Item {
                required property int index

                readonly property string glyph: clockDisplay.value.charAt(index)
                readonly property bool colon: glyph === ":"

                width: colon ? 14 : 42
                height: 84

                Repeater {
                  model: colon ? 2 : 35

                  delegate: Rectangle {
                    required property int index

                    readonly property int row: colon ? index * 4 + 1 : Math.floor(index / 5)
                    readonly property int column: colon ? 1 : index % 5
                    readonly property bool active: colon
                      ? true
                      : clockDisplay.glyphs[glyph] && clockDisplay.glyphs[glyph][row].charAt(column) === "1"

                    width: colon ? 7 : 7
                    height: colon ? 7 : 7
                    x: colon ? 3 : column * 8
                    y: colon ? (index === 0 ? 24 : 52) : row * 11
                    radius: 0
                    visible: active
                    color: Color.foreground
                  }
                }
              }
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: clockDisplay.bottom
          anchors.topMargin: Style.space(5)
          text: Qt.formatDateTime(root.displayDate, "dddd, MMMM d")
          color: Util.alpha(Color.foreground, 0.72)
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.82)
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
