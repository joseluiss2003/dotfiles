import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.ui

Item {
  id: root

  property real widgetWidth: 390
  property real widgetHeight: 270
  property int matrixFontSize: Math.max(11, Style.fontPx(0.95))
  property int cellWidth: Math.max(9, Math.round(matrixFontSize * 0.78))
  property int cellHeight: Math.max(12, Math.round(matrixFontSize * 1.12))
  property var columns: []
  property string glyphs: "01ABCDEFGHIJKLMNOPQRSTUVWXYZ"

  function resetColumns() {
    var rows = Math.max(1, Math.floor((widgetHeight - 78) / cellHeight))
    var count = Math.max(16, Math.floor((widgetWidth - 28) / cellWidth))
    var next = []
    for (var i = 0; i < count; i++) {
      next.push({
        head: -Math.random() * rows,
        length: 4 + Math.floor(Math.random() * Math.max(4, rows * 0.45)),
        speed: 0.45 + Math.random() * 1.15,
        seed: Math.floor(Math.random() * 100000)
      })
    }
    columns = next
    matrixCanvas.requestPaint()
  }

  function advance() {
    var rows = Math.max(1, Math.floor((matrixCanvas.height - 4) / cellHeight))
    var next = []
    for (var i = 0; i < columns.length; i++) {
      var c = columns[i]
      var head = c.head + c.speed
      if (head - c.length > rows + 1) {
        head = -2 - Math.random() * Math.max(3, rows * 0.35)
        c = {
          head: head,
          length: 4 + Math.floor(Math.random() * Math.max(4, rows * 0.45)),
          speed: 0.45 + Math.random() * 1.15,
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
    matrixCanvas.requestPaint()
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
      width: root.widgetWidth
      height: root.widgetHeight

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
          text: "MATRIX"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.92)
          font.weight: Font.DemiBold
        }

        Text {
          x: width - implicitWidth - Style.space(14)
          y: Style.space(9)
          text: "LIVE"
          color: Util.alpha(Color.accent, 0.82)
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.78)
          font.weight: Font.Medium
        }

        Canvas {
          id: matrixCanvas
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: header.bottom
          anchors.bottom: footer.top
          anchors.leftMargin: Style.space(14)
          anchors.rightMargin: Style.space(14)
          anchors.topMargin: Style.space(7)
          anchors.bottomMargin: Style.space(4)

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

              for (var row = Math.max(0, tail); row <= Math.min(rows, Math.ceil(head)); row++) {
                var distance = head - row
                if (distance < 0 || distance > column.length) continue

                var alpha = Math.max(0.08, 1.0 - (distance / column.length))
                if (distance < 1.0) alpha = 1.0

                ctx.fillStyle = Qt.rgba(
                  Color.accent.r,
                  Color.accent.g,
                  Color.accent.b,
                  alpha * 0.82
                )
                ctx.fillText(root.glyphFor(column, row), x, row * cellHeight)
              }
            }
          }
        }

        Text {
          id: footer
          x: Style.space(14)
          y: parent.height - implicitHeight - Style.space(8)
          text: "> matrix"
          color: Util.alpha(Color.foreground, 0.72)
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.78)
        }

        Text {
          x: footer.x + footer.implicitWidth + Style.space(10)
          y: footer.y
          text: "desktop"
          color: Util.alpha(Color.muted, 0.62)
          font.family: Style.font.family
          font.pixelSize: Style.fontPx(0.72)
        }
      }

      Timer {
        interval: 55
        repeat: true
        running: true
        onTriggered: root.advance()
      }

      Component.onCompleted: root.resetColumns()
    }
  }
}
