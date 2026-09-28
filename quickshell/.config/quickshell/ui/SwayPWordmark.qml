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
    "P": ["11110","10001","10001","11110","10000","10000","10000"]
  })

  readonly property string word: "SP"
  readonly property var logoPalette: Color.semanticColors && Array.isArray(Color.semanticColors.logo)
    ? Color.semanticColors.logo
    : []

  function logoColor(index, fallback) {
    if (index >= 0 && index < logoPalette.length)
      return Color.colorFromValue(logoPalette[index], fallback)
    return fallback
  }

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

      // Reuse the exact six-color logo ramp generated for Fastfetch.
      // Fastfetch renders $6 at the top and $1 at the bottom, so the lock
      // wordmark follows the same light -> dark vertical order.
      for (var row = 0; row < 7; row++) {
        var paletteIndex = Math.max(0, Math.min(5, 6 - row))
        var fallback = row < 2 ? root.highlightColor : root.color
        ctx.fillStyle = root.logoColor(paletteIndex, fallback)

        var cursorX = x
        for (var gi = 0; gi < root.word.length; gi++) {
          var rows = root.glyphs[root.word.charAt(gi)]

          for (var col = 0; col < rows[row].length; col++) {
            if (rows[row].charAt(col) !== "1") continue
            ctx.fillRect(
              cursorX + col * cell,
              y + row * cell,
              cell - gap,
              cell - gap
            )
          }

          cursorX += rows[0].length * cell + cell
        }
      }
    }

    Connections {
      target: root
      function onColorChanged() { canvas.requestPaint() }
      function onHighlightColorChanged() { canvas.requestPaint() }
      function onShadowColorChanged() { canvas.requestPaint() }
      function onPixelSizeChanged() { canvas.requestPaint() }
      function onLogoPaletteChanged() { canvas.requestPaint() }
    }

    Connections {
      target: Color
      function onSemanticColorsChanged() { canvas.requestPaint() }
    }

    Component.onCompleted: requestPaint()
  }
}
