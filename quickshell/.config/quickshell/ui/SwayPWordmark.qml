import QtQuick
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth

  // Large, compact block wordmark inspired by the approved reference:
  // heavy geometric letters, stepped corners and a deep offset extrusion.
  readonly property var letters: [
    [
      "11111",
      "10000",
      "10000",
      "11110",
      "00001",
      "00001",
      "11111"
    ],
    [
      "10001",
      "10001",
      "10001",
      "10101",
      "10101",
      "11011",
      "10001"
    ],
    [
      "10001",
      "10001",
      "10101",
      "10101",
      "10101",
      "11011",
      "10001"
    ],
    [
      "01110",
      "10001",
      "10001",
      "11111",
      "10001",
      "10001",
      "10001"
    ],
    [
      "10001",
      "10001",
      "01010",
      "00100",
      "00100",
      "00100",
      "00100"
    ],
    [
      "11110",
      "10001",
      "10001",
      "11110",
      "10000",
      "10000",
      "10000"
    ]
  ]

  readonly property int cols: 5
  readonly property int rows: 7
  readonly property real gap: 0.9
  readonly property real letterGap: 1.35

  // Keep the same wide proportion as the reference while fitting the
  // existing 330x92 LockView slot without touching LockView.qml.
  readonly property real unit: Math.min(
    (width - 10) / (5 * 5 + 4 * letterGap),
    (height - 8) / (7 + 2.2)
  )
  readonly property real glyphWidth: 5 * unit
  readonly property real glyphHeight: 7 * unit
  readonly property real wordWidth: 5 * glyphWidth + 4 * letterGap * unit
  readonly property real wordHeight: 7 * unit
  readonly property real left: (width - wordWidth) / 2
  readonly property real top: (height - wordHeight) / 2

  function paintLetter(ctx, letter, x, y, size, color) {
    ctx.fillStyle = color

    for (var r = 0; r < root.rows; r++) {
      var row = letter[r]
      for (var c = 0; c < root.cols; c++) {
        if (row.charAt(c) === "1")
          ctx.fillRect(
            x + c * size,
            y + r * size,
            size + 0.25,
            size + 0.25
          )
      }
    }
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: false

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      // Deep offset extrusion — the part that gives the mark the Omarchy-like
      // physical weight without adding a separate object to the lock screen.
      var extrusion = root.unit * 0.72
      var x = root.left
      var y = root.top

      for (var i = 0; i < root.letters.length; i++) {
        root.paintLetter(
          ctx,
          root.letters[i],
          x + extrusion,
          y + extrusion,
          root.unit,
          root.shadowColor
        )
        x += root.glyphWidth + root.letterGap * root.unit
      }

      // Main face: same accent as the clock.
      x = root.left
      ctx.fillStyle = root.color

      for (var j = 0; j < root.letters.length; j++) {
        root.paintLetter(
          ctx,
          root.letters[j],
          x,
          y,
          root.unit,
          root.color
        )
        x += root.glyphWidth + root.letterGap * root.unit
      }

      // Strong top cap, following the reference's light upper plane.
      // It remains the theme's highlight, while the clock stays pure accent.
      x = root.left
      var cap = Math.max(1.2, root.unit * 0.18)

      for (var k = 0; k < root.letters.length; k++) {
        var letter = root.letters[k]
        ctx.fillStyle = root.highlightColor

        for (var cr = 0; cr < root.rows; cr++) {
          var crow = letter[cr]
          for (var cc = 0; cc < root.cols; cc++) {
            if (crow.charAt(cc) === "1" && (cr === 0 || letter[cr - 1].charAt(cc) === "0")) {
              ctx.fillRect(
                x + cc * root.unit,
                y + cr * root.unit,
                root.unit + 0.25,
                cap
              )
            }
          }
        }

        x += root.glyphWidth + root.letterGap * root.unit
      }

      // A restrained lower shadow line makes the logo read clearly over any
      // lock-screen wallpaper.
      ctx.fillStyle = root.shadowColor
      ctx.globalAlpha = 0.72
      x = root.left
      for (var s = 0; s < root.letters.length; s++) {
        var sLetter = root.letters[s]
        for (var sr = 0; sr < root.rows; sr++) {
          var srow = sLetter[sr]
          for (var sc = 0; sc < root.cols; sc++) {
            if (srow.charAt(sc) === "1" && (sr === root.rows - 1 || sLetter[sr + 1].charAt(sc) === "0")) {
              ctx.fillRect(
                x + sc * root.unit,
                y + sr * root.unit + root.unit * 0.78,
                root.unit + 0.25,
                root.unit * 0.18
              )
            }
          }
        }
        x += root.glyphWidth + root.letterGap * root.unit
      }
      ctx.globalAlpha = 1.0
    }

    Connections {
      target: root
      function onColorChanged() { canvas.requestPaint() }
      function onHighlightColorChanged() { canvas.requestPaint() }
      function onShadowColorChanged() { canvas.requestPaint() }
      function onWidthChanged() { canvas.requestPaint() }
      function onHeightChanged() { canvas.requestPaint() }
    }

    Component.onCompleted: requestPaint()
  }
}