import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.core
import qs.ui

Item {
  id: root

  property real widgetSize: 260
  property var weatherService: shell ? shell.firstPartyServiceFor("swayp.weather") : null

  function refreshService() {
    weatherService = shell ? shell.firstPartyServiceFor("swayp.weather") : null
  }

  Component.onCompleted: refreshService()

  Connections {
    target: shell
    function onPluginIdChanged() { root.refreshService() }
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
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Style.space(18)
          anchors.rightMargin: Style.space(18)
          spacing: Style.space(8)

          Text {
            width: parent.width
            text: root.weatherService ? root.weatherService.locationName : "MADRID"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.fontPx(0.86)
            font.weight: Font.DemiBold
          }

          Row {
            spacing: Style.space(10)

            Text {
              text: root.weatherService && root.weatherService.available
                ? Math.round(root.weatherService.temperature) + "°C"
                : "—"
              color: Color.success
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(2.15)
              font.weight: Font.DemiBold
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: root.weatherService
                ? root.weatherService.condition
                : "LOADING"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.78)
            }
          }

          Rectangle {
            width: parent.width
            height: 1
            color: Util.alpha(Color.foreground, 0.14)
          }

          Grid {
            columns: 2
            columnSpacing: Style.space(22)
            rowSpacing: Style.space(7)

            Text {
              text: "HUM  " + (root.weatherService && root.weatherService.available
                ? Math.round(root.weatherService.humidity) + "%"
                : "—")
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.76)
            }

            Text {
              text: "WIND " + (root.weatherService && root.weatherService.available
                ? Math.round(root.weatherService.windSpeed) + " km/h"
                : "—")
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.fontPx(0.76)
            }
          }

          Text {
            text: root.weatherService && root.weatherService.loading
              ? "FETCHING..."
              : root.weatherService && root.weatherService.available
                ? "OPEN-METEO"
                : "NO DATA"
            color: Util.alpha(Color.foreground, 0.58)
            font.family: Style.font.family
            font.pixelSize: Style.fontPx(0.66)
          }
        }
      }
    }
  }
}
