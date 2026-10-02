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

        Item {
          id: clockDisplay
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: -Style.space(3)
          width: 360
          height: 92

          property string value: Qt.formatDateTime(root.displayDate, "HH:mm")

          Canvas {
            id: clockCanvas
            anchors.fill: parent

            onPaint: {
              var ctx = getContext("2d")
              ctx.clearRect(0, 0, width, height)
              ctx.fillStyle = Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, Color.foreground.a)

              var value = clockDisplay.value
              var digitW = 42
              var digitH = 68
              var stroke = 8
              var gap = 7
              var colonW = 14
              var totalW = digitW * 4 + gap * 3 + colonW + gap
              var startX = (width - totalW) / 2
              var top = (height - digitH) / 2

              function h(x, y, w) {
                ctx.fillRect(x, y, w, stroke)
              }

              function v(x, y, hgt) {
                ctx.fillRect(x, y, stroke, hgt)
              }

              function drawDigit(ch, x) {
                var right = x + digitW - stroke
                var mid = top + (digitH - stroke) / 2

                switch (ch) {
                case "0":
                  v(x, top, digitH)
                  v(right, top, digitH)
                  h(x + stroke, top, digitW - stroke * 2)
                  h(x + stroke, top + digitH - stroke, digitW - stroke * 2)
                  break
                case "1":
                  v(x + (digitW - stroke) / 2, top, digitH)
                  break
                case "2":
                  h(x, top, digitW)
                  h(x, mid, digitW)
                  h(x, top + digitH - stroke, digitW)
                  v(right, top + stroke, (digitH - stroke) / 2 - 2)
                  v(x, mid + stroke, (digitH - stroke) / 2 - 2)
                  break
                case "3":
                  h(x, top, digitW)
                  h(x, mid, digitW)
                  h(x, top + digitH - stroke, digitW)
                  v(right, top + stroke, mid - top - stroke)
                  v(right, mid + stroke, digitH - (mid - top) - stroke)
                  break
                case "4":
                  v(x, top, mid - top)
                  h(x, mid, digitW)
                  v(right, top, digitH)
                  break
                case "5":
                  h(x, top, digitW)
                  h(x, mid, digitW)
                  h(x, top + digitH - stroke, digitW)
                  v(x, top + stroke, mid - top - stroke)
                  v(right, mid + stroke, digitH - (mid - top) - stroke)
                  break
                case "6":
                  h(x, top, digitW)
                  h(x, mid, digitW)
                  h(x, top + digitH - stroke, digitW)
                  v(x, top + stroke, digitH - stroke * 2)
                  v(right, mid + stroke, digitH - (mid - top) - stroke)
                  break
                case "7":
                  h(x, top, digitW)
                  v(right, top + stroke, digitH - stroke)
                  break
                case "8":
                  h(x, top, digitW)
                  h(x, mid, digitW)
                  h(x, top + digitH - stroke, digitW)
                  v(x, top + stroke, digitH - stroke * 2)
                  v(right, top + stroke, digitH - stroke * 2)
                  break
                case "9":
                  h(x, top, digitW)
                  h(x, mid, digitW)
                  h(x, top + digitH - stroke, digitW)
                  v(x, top + stroke, mid - top - stroke)
                  v(right, top + stroke, digitH - stroke * 2)
                  break
                }
              }

              var x = startX
              for (var i = 0; i < value.length; i++) {
                var ch = value.charAt(i)
                if (ch === ":") {
                  ctx.fillRect(x + 4, top + 20, 7, 7)
                  ctx.fillRect(x + 4, top + 41, 7, 7)
                  x += colonW + gap
                } else {
                  drawDigit(ch, x)
                  x += digitW + gap
                }
              }
            }

            Component.onCompleted: requestPaint()
            Connections {
              target: root
              function onDisplayDateChanged() { clockCanvas.requestPaint() }
            }

            Connections {
              target: Color
              function onForegroundChanged() { clockCanvas.requestPaint() }
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
