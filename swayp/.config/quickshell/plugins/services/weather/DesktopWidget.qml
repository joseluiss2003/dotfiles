import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.core
import qs.ui

Item {
  id: root

  property var shell: null
  property real widgetSize: Style.space(260)
  property var weatherService: shell ? shell.firstPartyServiceFor("swayp.weather") : null

  function refreshService() {
    weatherService = shell ? shell.firstPartyServiceFor("swayp.weather") : null
  }

  onShellChanged: refreshService()
  Component.onCompleted: refreshService()

  function valueOrDash(value) {
    return root.weatherService && root.weatherService.available ? value : "—"
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: weatherWindow
      required property var modelData

      screen: modelData
      implicitWidth: root.widgetSize
      implicitHeight: root.widgetSize

      anchors.right: true
      anchors.bottom: true
      margins.right: Style.space(24) + Style.space(260) + Style.space(10)
      margins.bottom: Style.space(190) + Style.space(10) + Style.space(28)

      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Bottom

      BorderSurface {
        anchors.fill: parent
        color: Util.alpha(Color.background, 0.92)
        borderSpec: Border.flat(Util.alpha(Color.accent, 0.68), 1)

        Text {
          x: Style.space(14)
          y: Style.space(9)
          text: "> weather"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.78)
          font.weight: Font.DemiBold
        }

        Column {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.leftMargin: Style.space(18)
          anchors.rightMargin: Style.space(18)
          anchors.topMargin: Style.space(43)
          anchors.bottomMargin: Style.space(16)
          spacing: Style.space(10)

          Item {
            width: parent.width
            height: 170

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              text: root.weatherService ? root.weatherService.locationName : "HUELVA"
              color: Util.alpha(Color.foreground, 0.68)
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.72)
              font.weight: Font.DemiBold
            }

            Item {
              id: temperatureDisplay
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              anchors.topMargin: Style.space(43)
              width: 250
              height: 86

              property string value: root.weatherService && root.weatherService.available
                ? Math.round(root.weatherService.temperature) + "C"
                : "--C"

              Canvas {
                anchors.fill: parent

                onPaint: {
                  var ctx = getContext("2d")
                  ctx.clearRect(0, 0, width, height)
                  ctx.fillStyle = Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, Color.foreground.a)

                  var digitW = 50
                  var digitH = 76
                  var stroke = 11
                  var gap = 7
                  var degreeSize = 9
                  var value = temperatureDisplay.value
                  var totalW = digitW * 3 + gap * 2 + degreeSize + 12
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
                      v(x, top, digitH); v(right, top, digitH)
                      h(x, top, digitW)
                      h(x, top + digitH - stroke, digitW)
                      break
                    case "1":
                      v(x + (digitW - stroke) / 2, top, digitH)
                      break
                    case "2":
                      h(x, top, digitW); h(x, mid, digitW); h(x, top + digitH - stroke, digitW)
                      v(right, top + stroke, (digitH - stroke) / 2 - 2)
                      v(x, mid + stroke, (digitH - stroke) / 2 - 2)
                      break
                    case "3":
                      h(x, top, digitW); h(x, mid, digitW); h(x, top + digitH - stroke, digitW)
                      v(right, top + stroke, mid - top - stroke)
                      v(right, mid + stroke, digitH - (mid - top) - stroke)
                      break
                    case "4":
                      v(x, top, mid - top); h(x, mid, digitW); v(right, top, digitH)
                      break
                    case "5":
                      h(x, top, digitW); h(x, mid, digitW); h(x, top + digitH - stroke, digitW)
                      v(x, top + stroke, mid - top - stroke)
                      v(right, mid + stroke, digitH - (mid - top) - stroke)
                      break
                    case "6":
                      h(x, top, digitW); h(x, mid, digitW); h(x, top + digitH - stroke, digitW)
                      v(x, top + stroke, digitH - stroke * 2)
                      v(right, mid + stroke, digitH - (mid - top) - stroke)
                      break
                    case "7":
                      h(x, top, digitW); v(right, top + stroke, digitH - stroke)
                      break
                    case "8":
                      h(x, top, digitW); h(x, mid, digitW); h(x, top + digitH - stroke, digitW)
                      v(x, top + stroke, digitH - stroke * 2)
                      v(right, top + stroke, digitH - stroke * 2)
                      break
                    case "9":
                      h(x, top, digitW); h(x, mid, digitW); h(x, top + digitH - stroke, digitW)
                      v(x, top + stroke, mid - top - stroke)
                      v(right, top + stroke, digitH - stroke * 2)
                      break
                    }
                  }

                  function drawC(x) {
                    h(x, top, digitW)
                    h(x, top + digitH - stroke, digitW)
                    v(x, top, digitH)
                  }

                  var x = startX
                  drawDigit(value.charAt(0), x)
                  x += digitW + gap
                  drawDigit(value.charAt(1), x)
                  x += digitW + gap + 3

                  ctx.fillRect(x, top, degreeSize, degreeSize)
                  x += degreeSize + 9
                  drawC(x)
                }
              }
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              anchors.topMargin: Style.space(128)
              text: root.weatherService ? root.weatherService.condition : "LOADING"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.78)
              font.weight: Font.DemiBold
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              anchors.topMargin: Style.space(151)
              text: root.weatherService && root.weatherService.available
                ? "FEELS " + Math.round(root.weatherService.apparentTemperature) + "°C"
                : "FEELS —"
              color: Util.alpha(Color.foreground, 0.5)
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.64)
            }
          }
        }
      }
    }
  }
}
