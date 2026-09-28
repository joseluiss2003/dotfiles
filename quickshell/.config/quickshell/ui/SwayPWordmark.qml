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

  readonly property var rows: [
    "   ███████╗ ██╗    ██╗  █████╗  ██╗   ██╗ ██████╗",
    "   ██╔════╝ ██║    ██║ ██╔══██╗ ╚██╗ ██╔╝ ██╔══██╗",
    "   ███████╗ ██║ █╗ ██║ ███████║  ╚████╔╝  ██████╔╝",
    "   ╚════██║ ██║███╗██║ ██╔══██║   ╚██╔╝   ██╔═══╝",
    "   ███████║ ╚███╔███╔╝ ██║  ██║    ██║    ██║",
    "   ╚══════╝  ╚══╝╚══╝  ╚═╝  ╚═╝    ╚═╝    ╚═╝"
  ]

  // Terminal glyphs expressed as connected strokes. Keeping one cell per
  // Unicode character makes the QML rendering visually match the CLI.
  readonly property var glyphs: ({
    "█": "F",
    "═": "H",
    "║": "V",
    "╔": "TL",
    "╗": "TR",
    "╚": "BL",
    "╝": "BR",
    " ": "S"
  })

  function logoColor(index, fallback) {
    if (index >= 0 && index < logoPalette.length)
      return Color.colorFromValue(logoPalette[index], fallback)
    return fallback
  }

  function drawGlyph(ctx, glyph, x, y, w, h, thickness) {
    var kind = glyphs[glyph] || "S"
    if (kind === "S") return

    var t = thickness
    var midY = y + (h - t) / 2
    var midX = x + (w - t) / 2

    ctx.fillStyle = root.logoColor(0, root.color)

    if (kind === "F") {
      ctx.fillRect(x, y, w, h)
    } else if (kind === "H") {
      ctx.fillRect(x, midY, w, t)
    } else if (kind === "V") {
      ctx.fillRect(midX, y, t, h)
    } else if (kind === "TL") {
      ctx.fillRect(x, y, w, t)
      ctx.fillRect(x, y, t, h)
    } else if (kind === "TR") {
      ctx.fillRect(x, y, w, t)
      ctx.fillRect(x + w - t, y, t, h)
    } else if (kind === "BL") {
      ctx.fillRect(x, y + h - t, w, t)
      ctx.fillRect(x, y, t, h)
    } else if (kind === "BR") {
      ctx.fillRect(x, y + h - t, w, t)
      ctx.fillRect(x + w - t, y, t, h)
    }
  }

  readonly property int columns: {
    var max = 0
    for (var i = 0; i < root.rows.length; i++)
      max = Math.max(max, root.rows[i].length)
    return max
  }

  readonly property real cellWidth: Math.min(width / root.columns, height / 7.0)
  readonly property real cellHeight: root.cellWidth
  readonly property real markWidth: root.columns * root.cellWidth
  readonly property real markHeight: 6 * root.cellHeight

  Canvas {
    id: canvas
    anchors.centerIn: parent
    width: root.markWidth
    height: root.markHeight
    antialiasing: false

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var thickness = Math.max(1.8, root.cellWidth * 0.34)

      for (var row = 0; row < root.rows.length; row++) {
        var line = root.rows[row]
        var y = row * root.cellHeight

        ctx.fillStyle = root.logoColor(
          5 - row,
          row < 2 ? root.highlightColor : root.color
        )

        for (var col = 0; col < root.columns; col++) {
          var glyph = col < line.length ? line.charAt(col) : " "
          root.drawGlyph(ctx, glyph, col * root.cellWidth, y, root.cellWidth, root.cellHeight, thickness)
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