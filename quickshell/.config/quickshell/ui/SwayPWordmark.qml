import QtQuick
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth
  property real pixelSize: Math.max(4, Math.min(width, height) / 9)

  readonly property var glyphs: ({
    "S": ["11111","10000","10000","11110","00001","00001","11110"],
    "W": ["1000001","1000001","1000001","1010101","1010101","0101010","0100010"],
    "A": ["01110","10001","10001","11111","10001","10001","10001"],
    "Y": ["10001","10001","01010","00100","00100","00100","00100"],
    "P": ["11110","10001","10001","11110","10000","10000","10000"]
  })

  readonly property string word: "SWAYP"

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: false

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var cell = root.pixelSize
      var gap = Math.max(1, Math.round(cell * 0.18))
      var shadowOffset = Math.max(1, Math.round(cell * 0.28))
      var totalWidth = 0

      for (var i = 0; i < root.word.length; i++) {
        var glyph = root.glyphs[root.word.charAt(i)]
        totalWidth += glyph[0].length * cell
        if (i < root.word.length - 1) totalWidth += cell
      }

      var x = (width - totalWidth) / 2
      var y = (height - 7 * cell) / 2

      function drawLayer(color, offsetX, offsetY) {
        ctx.fillStyle = color
        var cursorX = x

        for (var gi = 0; gi < root.word.length; gi++) {
          var rows = root.glyphs[root.word.charAt(gi)]

          for (var row = 0; row < rows.length; row++) {
            for (var col = 0; col < rows[row].length; col++) {
              if (rows[row].charAt(col) !== "1") continue
              ctx.fillRect(
                cursorX + col * cell + offsetX,
                y + row * cell + offsetY,
                cell - gap,
                cell - gap
              )
            }
          }

          cursorX += rows[0].length * cell + cell
        }
      }

      drawLayer(root.shadowColor, 0, shadowOffset)
      drawLayer(root.color, 0, 0)

      // A flat highlight band keeps the Omarchy-inspired pixel depth without
      // introducing a gradient: the top two rows are a second theme color.
      ctx.fillStyle = root.highlightColor
      var cursor = x
      for (var li = 0; li < root.word.length; li++) {
        var rows2 = root.glyphs[root.word.charAt(li)]
        for (var rr = 0; rr < 2; rr++) {
          for (var cc = 0; cc < rows2[rr].length; cc++) {
            if (rows2[rr].charAt(cc) !== "1") continue
            ctx.fillRect(
              cursor + cc * cell,
              y + rr * cell,
              cell - gap,
              cell - gap
            )
          }
        }
        cursor += rows2[0].length * cell + cell
      }
    }

    Connections {
      target: root
      function onColorChanged() { canvas.requestPaint() }
      function onHighlightColorChanged() { canvas.requestPaint() }
      function onShadowColorChanged() { canvas.requestPaint() }
      function onPixelSizeChanged() { canvas.requestPaint() }
    }

    Component.onCompleted: requestPaint()
  }
}
