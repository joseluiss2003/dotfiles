import QtQuick
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth

  readonly property var rows: [
    "███████╗ ██╗    ██╗  █████╗  ██╗   ██╗ ██████╗",
    "██╔════╝ ██║    ██║ ██╔══██╗ ╚██╗ ██╔╝ ██╔══██╗",
    "███████╗ ██║ █╗ ██║ ███████║  ╚████╔╝  ██████╔╝",
    "╚════██║ ██║███╗██║ ██╔══██║   ╚██╔╝   ██╔═══╝",
    "███████║ ╚███╔███╔╝ ██║  ██║    ██║    ██║",
    "╚══════╝  ╚══╝╚══╝  ╚═╝  ╚═╝    ╚═╝    ╚═╝"
  ]

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

  function drawGlyph(ctx, glyph, x, y, w, h, thickness, layer) {
    var kind = glyphs[glyph] || "S"
    if (kind === "S") return

    var t = thickness
    var midY = y + (h - t) / 2
    var midX = x + (w - t) / 2

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

  // Large enough to make the wordmark a real lock-screen focal point.
  readonly property real cellWidth: Math.min(
    (width - 16) / root.columns,
    (height - 8) / 6
  )
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

      var thickness = Math.max(2.2, root.cellWidth * 0.36)

      // Omarchy-inspired depth: a compact dark extrusion behind the accent.
      // It gives the Unicode wordmark the heavier, more physical silhouette
      // the lock screen needs without changing the clock's accent color.
      ctx.fillStyle = root.shadowColor
      for (var shadowRow = 0; shadowRow < root.rows.length; shadowRow++) {
        var shadowLine = root.rows[shadowRow]
        for (var shadowCol = 0; shadowCol < root.columns; shadowCol++) {
          var shadowGlyph = shadowCol < shadowLine.length
            ? shadowLine.charAt(shadowCol)
            : " "
          root.drawGlyph(
            ctx,
            shadowGlyph,
            shadowCol * root.cellWidth + 2.4,
            shadowRow * root.cellHeight + 3.2,
            root.cellWidth,
            root.cellHeight,
            thickness,
            "shadow"
          )
        }
      }

      // Crisp outline immediately around the main mark. This is the part that
      // keeps the old Unicode-border character while preserving a clean logo.
      ctx.fillStyle = root.shadowColor
      var outline = Math.max(1.4, root.cellWidth * 0.20)
      for (var outlineRow = 0; outlineRow < root.rows.length; outlineRow++) {
        var outlineLine = root.rows[outlineRow]
        for (var outlineCol = 0; outlineCol < root.columns; outlineCol++) {
          var outlineGlyph = outlineCol < outlineLine.length
            ? outlineLine.charAt(outlineCol)
            : " "
          for (var oy = -1; oy <= 1; oy++) {
            for (var ox = -1; ox <= 1; ox++) {
              if (ox === 0 && oy === 0) continue
              root.drawGlyph(
                ctx,
                outlineGlyph,
                outlineCol * root.cellWidth + ox * outline,
                outlineRow * root.cellHeight + oy * outline,
                root.cellWidth,
                root.cellHeight,
                thickness,
                "outline"
              )
            }
          }
        }
      }

      // Main face: exactly the same accent used by the clock.
      ctx.fillStyle = root.color
      for (var row = 0; row < root.rows.length; row++) {
        var line = root.rows[row]
        for (var col = 0; col < root.columns; col++) {
          var glyph = col < line.length ? line.charAt(col) : " "
          root.drawGlyph(
            ctx,
            glyph,
            col * root.cellWidth,
            row * root.cellHeight,
            root.cellWidth,
            root.cellHeight,
            thickness,
            "face"
          )
        }
      }

      // Small upper highlight, inspired by the light cap visible on Omarchy's
      // wordmark. It is deliberately restrained so the face remains accent.
      ctx.fillStyle = root.highlightColor
      var highlight = Math.max(1.0, root.cellWidth * 0.12)
      for (var hr = 0; hr < root.rows.length; hr++) {
        var hline = root.rows[hr]
        for (var hc = 0; hc < root.columns; hc++) {
          var hg = hc < hline.length ? hline.charAt(hc) : " "
          var hk = root.glyphs[hg] || "S"
          if (hk === "F" || hk === "H" || hk === "TL" || hk === "TR") {
            ctx.fillRect(
              hc * root.cellWidth,
              hr * root.cellHeight,
              root.cellWidth,
              highlight
            )
          }
        }
      }
    }

    Connections {
      target: root
      function onColorChanged() { canvas.requestPaint() }
      function onHighlightColorChanged() { canvas.requestPaint() }
      function onShadowColorChanged() { canvas.requestPaint() }
    }

    Component.onCompleted: requestPaint()
  }
}