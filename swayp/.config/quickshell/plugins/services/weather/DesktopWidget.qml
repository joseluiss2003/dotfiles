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
          anchors.bottomMargin: Style.space(15)
          spacing: Style.space(9)

          Row {
            width: parent.width
            spacing: Style.space(12)

            Column {
              width: parent.width * 0.58
              spacing: Style.space(2)

              Text {
                text: root.weatherService ? root.weatherService.locationName : "MADRID"
                color: Util.alpha(Color.foreground, 0.72)
                font.family: Style.font.family
                font.pixelSize: Style.fontPx(0.72)
                font.weight: Font.DemiBold
              }

              Text {
                text: root.valueOrDash(Math.round(root.weatherService.temperature) + "°C")
                color: Color.accent
                font.family: Style.font.family
                font.pixelSize: Style.fontPx(2.25)
                font.weight: Font.DemiBold
              }
            }

            Column {
              width: parent.width * 0.42 - Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(3)

              Text {
                width: parent.width
                text: root.weatherService
                  ? root.weatherService.condition
                  : "LOADING"
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.fontPx(0.76)
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
              }

              Text {
                text: root.weatherService && root.weatherService.available
                  ? "FEELS " + Math.round(root.weatherService.apparentTemperature) + "°C"
                  : "FEELS —"
                color: Util.alpha(Color.foreground, 0.58)
                font.family: Style.font.family
                font.pixelSize: Style.fontPx(0.66)
              }
            }
          }

          Rectangle {
            width: parent.width
            height: 1
            color: Util.alpha(Color.foreground, 0.12)
          }

          Grid {
            width: parent.width
            columns: 2
            columnSpacing: Style.space(24)
            rowSpacing: Style.space(9)

            Text {
              text: "HUM    " + root.valueOrDash(Math.round(root.weatherService.humidity) + "%")
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.72)
            }

            Text {
              text: "WIND   " + root.valueOrDash(Math.round(root.weatherService.windSpeed) + " km/h")
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.72)
            }

            Text {
              text: "RAIN   " + root.valueOrDash(root.weatherService.precipitation.toFixed(1) + " mm")
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.72)
            }

            Text {
              text: root.weatherService && root.weatherService.available
                ? "UPDATE " + String(root.weatherService.updatedAt).split("T")[1].slice(0, 5)
                : "UPDATE —"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.72)
            }
          }

          Item {
            width: 1
            height: 1
          }

          Text {
            text: root.weatherService && root.weatherService.loading
              ? "FETCHING..."
              : root.weatherService && root.weatherService.available
                ? "OPEN-METEO / CURRENT"
                : "NO DATA"
            color: Util.alpha(Color.foreground, 0.45)
            font.family: Style.font.family
            font.pixelSize: Style.fontPx(0.62)
          }
        }
      }
    }
  }
}
