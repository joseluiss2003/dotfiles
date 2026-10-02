import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

Item {
  id: root

  property real widgetWidth: 520
  property real widgetHeight: 190
  property int matrixFontSize: Math.max(11, Style.fontPx(0.98))
  property int cellWidth: Math.max(8, Math.round(matrixFontSize * 0.72))
  property int cellHeight: Math.max(12, Math.round(matrixFontSize * 1.02))
  property var columns: []
  property real animationTime: 0
  property string glyphs: "01ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz<>+-=/*\\|:;.,~^[]{}#%&@?"

  function newColumn(rows, startAbove) {
    var trail = 4 + Math.floor(Math.random() * Math.max(5, Math.min(12, rows * 0.7)))
    return {
      head: startAbove
        ? -2 - Math.random() * Math.max(3, rows * 0.8)
        : -Math.random() * rows,
      trail: trail,
      speed: 34 + Math.random() * 42,
      seed: Math.floor(Math.random() * 100000),
      brightness: 0.78 + Math.random() * 0.22,
      startTime: root.animationTime
    }
  }

  function resetColumns() {
    var rows = Math.max(1, Math.floor((widgetHeight - 64) / cellHeight))
    var count = Math.max(24, Math.floor((widgetWidth - 28) / cellWidth))
    var next = []

    for (var i = 0; i < count; i++) {
      var column = newColumn(rows, false)
      if (Math.random() < 0.22)
        column.head -= Math.random() * rows * 0.75
      next.push(column)
    }

    columns = next
  }

  function headFor(column) {
    return column.head + (column.speed * (animationTime - column.startTime) / cellHeight)
  }

  function glyphFor(column, segment) {
    var phase = Math.floor(headFor(column) * 0.22)
    var seed = column.seed + segment * 31 + phase * 7
    var index = Math.abs(seed * 13 + column.seed * 7) % glyphs.length
    return glyphs.charAt(index)
  }

  function advance(deltaSeconds) {
    animationTime += deltaSeconds

    var rows = Math.max(1, Math.floor((root.widgetHeight - 64) / cellHeight))
    var changed = false
    var next = columns.slice()

    for (var i = 0; i < next.length; i++) {
      var c = next[i]
      if (headFor(c) - c.trail > rows + 1) {
        next[i] = newColumn(rows, true)
        changed = true
      }
    }

    if (changed)
      columns = next
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: matrixWindow
      required property var modelData

      screen: modelData
      implicitWidth: root.widgetWidth
      implicitHeight: root.widgetHeight

      anchors.right: true
      anchors.bottom: true
      margins.right: Style.space(24)
      margins.bottom: Style.space(28)

      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Bottom

      BorderSurface {
        id: surface
        anchors.fill: parent
        color: Util.alpha(Color.background, 0.92)
        borderSpec: Border.flat(Util.alpha(Color.accent, 0.68), 1)

        Text {
          id: header
          x: Style.space(14)
          y: Style.space(9)
          text: "> matrix"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.78)
          z: 2
        }

        Item {
          id: matrixArea
          z: 1
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: header.bottom
          anchors.bottom: parent.bottom
          anchors.leftMargin: Style.space(14)
          anchors.rightMargin: Style.space(14)
          anchors.topMargin: Style.space(7)
          anchors.bottomMargin: Style.space(12)
          clip: true

          Repeater {
            model: root.columns

            delegate: Item {
              required property var modelData
              required property int index
              property var columnData: modelData
              property real head: root.headFor(columnData)

              x: index * root.cellWidth
              width: root.cellWidth
              height: matrixArea.height

              Repeater {
                model: columnData.trail + 1

                delegate: Text {
                  required property int index
                  property int segment: index + Math.floor(head - columnData.trail)

                  x: 0
                  y: (index - (head - Math.floor(head))) * root.cellHeight
                  text: root.glyphFor(columnData, segment)
                  color: Qt.rgba(
                    Color.accent.r,
                    Color.accent.g,
                    Color.accent.b,
                    Math.max(
                      0.035,
                      Math.pow(
                        1.0 - ((head - segment) / Math.max(1, columnData.trail)),
                        1.55
                      ) * columnData.brightness * 0.9
                    )
                  )
                  font.family: Style.font.family
                  font.pixelSize: root.matrixFontSize
                  lineHeight: root.cellHeight
                  renderType: Text.NativeRendering
                }
              }
            }
          }
        }
      }

      FrameAnimation {
        running: true
        onTriggered: root.advance(frameTime)
      }

      Component.onCompleted: root.resetColumns()
    }
  }
}
