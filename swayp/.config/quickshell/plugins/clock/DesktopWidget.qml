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
          height: 82

          property string value: Qt.formatDateTime(root.displayDate, "HH:mm")
          property var segments: ({
            "0": [true, true, true, true, true, true, false],
            "1": [false, true, true, false, false, false, false],
            "2": [true, true, false, true, true, false, true],
            "3": [true, true, true, true, false, false, true],
            "4": [false, true, true, false, false, true, true],
            "5": [true, false, true, true, false, true, true],
            "6": [true, false, true, true, true, true, true],
            "7": [true, true, true, false, false, false, false],
            "8": [true, true, true, true, true, true, true],
            "9": [true, true, true, true, false, true, true]
          })

          Row {
            anchors.centerIn: parent
            spacing: Style.space(7)

            Repeater {
              model: clockDisplay.value.length

              delegate: Item {
                required property int index

                readonly property string glyph: clockDisplay.value.charAt(index)
                readonly property bool isOne: glyph === "1"
                readonly property bool colon: glyph === ":"

                width: colon ? 16 : 50
                height: 76

                Rectangle {
                  visible: isOne
                  x: 21
                  y: 6
                  width: 9
                  height: 64
                  color: Color.foreground
                  radius: 0
                }

                Repeater {
                  model: colon ? 2 : 7

                  delegate: Rectangle {
                    required property int index

                    readonly property bool active: colon
                      ? true
                      : (!isOne && clockDisplay.segments[glyph][index])

                    visible: active
                    color: Color.foreground
                    radius: 0

                    width: colon ? 8 : [42, 9, 9, 42, 9, 9, 42][index]
                    height: colon ? 8 : [9, 34, 34, 9, 34, 34, 9][index]

                    x: colon
                      ? 4
                      : [4, 37, 37, 4, 0, 0, 4][index]
                    y: colon
                      ? (index === 0 ? 26 : 50)
                      : [0, 4, 40, 67, 40, 4, 34][index]
                  }
                }
              }
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: clockDisplay.bottom
          anchors.topMargin: Style.space(9)
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
