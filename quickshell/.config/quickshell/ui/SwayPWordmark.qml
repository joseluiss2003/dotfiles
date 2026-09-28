import QtQuick
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth
  property var logoPalette: Color.semanticColors && Array.isArray(Color.semanticColors.logo)
    ? Color.semanticColors.logo
    : []

  // The exact six CLI rows, represented as terminal glyph geometry.
  // Each row is kept as text data so the visual design remains identical
  // to the approved Fastfetch wordmark, while rendering each glyph ourselves
  // avoids QML font-metric differences.
  readonly property var rows: [
    "   ███████╗ ██╗    ██╗  █████╗  ██╗   ██╗ ██████╗",
    "   ██╔════╝ ██║    ██║ ██╔══██╗ ╚██╗ ██╔╝ ██╔══██╗",
    "   ███████╗ ██║ █╗ ██║ ███████║  ╚████╔╝  ██████╔╝",
    "   ╚════██║ ██║███╗██║ ██╔══██║   ╚██╔╝   ██╔═══╝",
    "   ███████║ ╚███╔███╔╝ ██║  ██║    ██║    ██║",
    "   ╚══════╝  ╚══╝╚══╝  ╚═╝  ╚═╝    ╚═╝    ╚═╝"
  ]

  readonly property var glyphs: ({
    "█": "111",
    "╗": "110",
    "╔": "011",
    "╝": "110",
    "╚": "011",
    "═": "111",
    "║": "101",
    " ": "000"
  })

  function logoColor(index, fallback) {
    if (index >= 0 && index < logoPalette.length)
      return Color.colorFromValue(logoPalette[index], fallback)
    return fallback
  }

  // Each Unicode glyph is converted into a compact 3x3 block pattern.
  // This preserves the block-character silhouette while guaranteeing that
  // adjacent glyphs share the same cell metrics.
  function glyphPattern(ch) {
    var p = glyphs[ch]
    if (p !== undefined) return p
    return "000"
  }

  readonly property int columns: 58
  readonly property real cellWidth: Math.min(width / columns, height / 8.0)
  readonly property real cellHeight: cellWidth
  readonly property real markWidth: columns * cellWidth
  readonly property real markHeight: 6 * cellHeight

  Canvas {
    id: canvas
    anchors.centerIn: parent
    width: root.markWidth
    height: root.markHeight
    antialiasing: false

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      for (var row = 0; row < root.rows.length; row++) {
        ctx.fillStyle = root.logoColor(
          5 - row,
          row < 2 ? root.highlightColor : root.color
        )

        var line = root.rows[row]
        var x = 0

        for (var i = 0; i < line.length; i++) {
          var pattern = root.glyphPattern(line.charAt(i))

          for (var px = 0; px < 3; px++) {
            if (pattern.charAt(px) !== "1") continue

            // A terminal block glyph is treated as a filled cell. The
            // horizontal/vertical strokes are deliberately kept tight so
            // the result reads as the same Unicode artwork rather than a
            // generic pixel font.
            ctx.fillRect(
              x + px * (root.cellWidth / 3),
              row * root.cellHeight,
              root.cellWidth / 3,
              root.cellHeight
            )
          }

          x += root.cellWidth
        }
      }
    }

    Connections {
      target: root
      function onLogoPaletteChanged() { canvas.requestPaint() }
      function onColorChanged() { canvas.requestPaint() }
      function onHighlightColorChanged() { canvas.requestPaint() }
      function onShadowColorChanged() { canvas.requestPaint() }
    }

    Connections {
      target: Color
      function onSemanticColorsChanged() {
        root.logoPalette = Color.semanticColors && Array.isArray(Color.semanticColors.logo)
          ? Color.semanticColors.logo
          : []
        canvas.requestPaint()
      }
    }

    Component.onCompleted: requestPaint()
  }
}
