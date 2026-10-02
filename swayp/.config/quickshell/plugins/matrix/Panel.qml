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
  property string glyphs: "01ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz<>+-=/*\\|:;.,~^[]{}#%&@?"

  function resetColumns() {
    var rows = Math.max(1, Math.floor((widgetHeight - 64) / cellHeight))
    var count = Math.max(24, Math.floor((widgetWidth - 28) / cellWidth))
    var next = []
    for (var i = 0; i < count; i++) {
      next.push({
        head: -Math.random() * rows,
        length: 5 + Math.floor(Math.random() * Math.max(5, rows * 0.75)),
        speed: 0.08 + Math.random() * 0.12,
        seed: Math.floor(Math.random() * 100000)
      })
    }
    columns = next
  }

  function advance() {
    var rows = Math.max(1, Math.floor((root.widgetHeight - 64) / cellHeight))
    var next = []
    for (var i = 0; i < columns.length; i++) {
      var c = columns[i]
      var head = c.head + c.speed
      if (head - c.length > rows + 1) {
        head = -2 - Math.random() * Math.max(3, rows * 0.35)
        c = {
          head: head,
          length: 5 + Math.floor(Math.random() * Math.max(5, rows * 0.75)),
          speed: 0.08 + Math.random() * 0.12,
          seed: Math.floor(Math.random() * 100000)
        }
      } else {
        c = {
          head: head,
          length: c.length,
          speed: c.speed,
          seed: c.seed
        }
      }
      next.push(c)
    }
    columns = next
  }

  function glyphFor(column, row) {
    var seed = column.seed + row * 17 + Math.floor(column.head * 3)
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
              var tail = Math.floor(head - column.length)
              var fractionalOffset = (head - Math.floor(head)) * cellHeight

              for (var row = Math.max(0, tail); row <= Math.min(rows, Math.ceil(head)); row++) {
                var distance = head - row
                if (distance < 0 || distance > column.length) continue

                var alpha = Math.max(0.08, 1.0 - (distance / column.length))
                if (distance < 1.0) alpha = 1.0
                else if (distance < 2.5) alpha = Math.min(1.0, alpha * 1.15)

                ctx.fillStyle = Qt.rgba(
                  Color.accent.r,
                  Color.accent.g,
                  Color.accent.b,
                  alpha * 0.95
                )
                ctx.fillText(root.glyphFor(column, row), x, row * cellHeight + fractionalOffset)
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
