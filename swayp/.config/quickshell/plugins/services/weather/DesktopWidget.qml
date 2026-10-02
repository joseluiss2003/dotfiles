import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.core
import qs.ui

Item {
  id: root

  property var shell: null
  property real widgetSize: 260
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
            height: 105

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              text: root.weatherService ? root.weatherService.locationName : "HUELVA"
              color: Util.alpha(Color.foreground, 0.68)
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.72)
              font.weight: Font.DemiBold
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              anchors.topMargin: Style.space(18)
              text: root.valueOrDash(Math.round(root.weatherService.temperature) + "°C")
              color: Color.accent
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(2.45)
              font.weight: Font.DemiBold
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              anchors.topMargin: Style.space(66)
              text: root.weatherService ? root.weatherService.condition : "LOADING"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.78)
              font.weight: Font.DemiBold
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              anchors.topMargin: Style.space(83)
              text: root.weatherService && root.weatherService.available
                ? "FEELS " + Math.round(root.weatherService.apparentTemperature) + "°C"
                : "FEELS —"
              color: Util.alpha(Color.foreground, 0.5)
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.64)
            }
          }

          Rectangle {
            width: parent.width
            height: 1
            color: Util.alpha(Color.foreground, 0.12)
          }

          Row {
            width: parent.width
            spacing: 0

            Text {
              width: parent.width / 2
              text: "HUM    " + root.valueOrDash(Math.round(root.weatherService.humidity) + "%")
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.7)
            }

            Text {
              width: parent.width / 2
              text: "WIND   " + root.valueOrDash(Math.round(root.weatherService.windSpeed) + " km/h")
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.7)
            }
          }

          Row {
            width: parent.width
            spacing: 0

            Text {
              width: parent.width / 2
              text: "RAIN   " + root.valueOrDash(root.weatherService.precipitation.toFixed(1) + " mm")
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.7)
            }

            Text {
              width: parent.width / 2
              text: root.weatherService && root.weatherService.available
                ? "H/L    " + Math.round(root.weatherService.highTemperature) + "°/" + Math.round(root.weatherService.lowTemperature) + "°"
                : "H/L    —"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.7)
            }
          }

          Row {
            width: parent.width
            spacing: 0

            Text {
              width: parent.width / 2
              text: root.weatherService && root.weatherService.available
                ? "UPDATE " + String(root.weatherService.updatedAt).split("T")[1].slice(0, 5)
                : "UPDATE —"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.7)
            }

            Text {
              width: parent.width / 2
              text: root.weatherService && root.weatherService.loading
                ? "FETCHING..."
                : root.weatherService && root.weatherService.available
                  ? "CURRENT"
                  : "NO DATA"
              color: Util.alpha(Color.foreground, 0.42)
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.62)
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }
    }
  }
}
