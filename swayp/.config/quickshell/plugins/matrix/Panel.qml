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
  property int frame: 0
  property string glyphs: "01ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz<>+-=/*\\|:;.,~^[]{}#%&@?"

  function newColumn(rows, startAbove) {
    var trail = 4 + Math.floor(Math.random() * Math.max(5, Math.min(12, rows * 0.7)))
    return {
      head: startAbove
        ? -2 - Math.random() * Math.max(3, rows * 0.8)
        : -Math.random() * rows,
      trail: trail,
      speed: 0.055 + Math.random() * 0.08,
      seed: Math.floor(Math.random() * 100000),
      brightness: 0.78 + Math.random() * 0.22
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

    frame = 0
    columns = next
  }

  function advance() {
    var rows = Math.max(1, Math.floor((root.widgetHeight - 64) / cellHeight))
    var next = []

    frame++

    for (var i = 0; i < columns.length; i++) {
      var c = columns[i]
      var head = c.head + c.speed

      if (head - c.trail > rows + 1) {
        c = newColumn(rows, true)
      } else {
        c = {
          head: head,
          trail: c.trail,
          speed: c.speed,
          seed: c.seed,
          brightness: c.brightness
        }
      }

      next.push(c)
    }

    columns = next
  }

  function glyphFor(column, segment) {
    // Change characters occasionally, but not every frame, so the streams
    // retain the characteristic terminal flicker without visual jitter.
    var phase = Math.floor(column.head * 0.22)
    var seed = column.seed + segment * 31 + phase * 7
    var index = Math.abs(seed * 13 + column.seed * 7) % glyphs.length
    return glyphs.charAt(index)
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

        Canvas {
          id: matrixCanvas
          z: 1
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: header.bottom
          anchors.bottom: parent.bottom
          anchors.leftMargin: Style.space(14)
          anchors.rightMargin: Style.space(14)
          anchors.topMargin: Style.space(7)
          anchors.bottomMargin: Style.space(12)

          onWidthChanged: root.resetColumns()
          onHeightChanged: root.resetColumns()

          onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.font = matrixFontSize + "px '" + Style.font.family + "'"
            ctx.textBaseline = "top"

            var rows = Math.max(1, Math.floor(height / cellHeight))

            for (var i = 0; i < root.columns.length; i++) {
              var column = root.columns[i]
              var x = i * cellWidth
              if (x >= width) continue

              var head = column.head
              var first = Math.floor(head - column.trail)
              var last = Math.ceil(head)

              for (var segment = first; segment <= last; segment++) {
                var distance = head - segment
                if (distance < 0 || distance > column.trail) continue

                var y = (segment - (head - Math.floor(head))) * cellHeight
                if (y < -cellHeight || y > height) continue

                var normalized = distance / Math.max(1, column.trail)
                var alpha = Math.pow(1.0 - normalized, 1.55) * column.brightness

                if (distance < 0.55) {
                  alpha = Math.min(1.0, 0.98 * column.brightness)
                } else if (distance < 1.6) {
                  alpha = Math.min(0.82, alpha + 0.22)
                }

                ctx.fillStyle = Qt.rgba(
                  Color.accent.r,
                  Color.accent.g,
                  Color.accent.b,
                  Math.max(0.035, alpha * 0.9)
                )

                ctx.fillText(root.glyphFor(column, segment), x, y)
              }
            }
          }
        }
      }

      Timer {
        interval: 16
        repeat: true
        running: true

        onTriggered: {
          root.advance()
          matrixCanvas.requestPaint()
        }
      }

      Component.onCompleted: root.resetColumns()
    }
  }
}
