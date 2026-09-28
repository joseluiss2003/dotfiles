import QtQuick
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth

  // Geometric SWAYP built from the approved reference.  The letters are
  // deliberately chunky, wide and stepped instead of using a font.
  readonly property var shapes: [
    // S
    [
      [8,0],[92,0],[92,16],[24,16],[24,28],[78,28],
      [78,42],[24,42],[24,54],[92,54],[92,70],[8,70],
      [8,58],[0,58],[0,42],[8,42],[8,28],[0,28],[0,12],[8,12]
    ],
    // W
    [
      [0,0],[18,0],[18,54],[27,54],[27,18],[45,18],
      [45,54],[54,54],[54,0],[72,0],[72,70],[43,70],
      [36,62],[29,70],[0,70]
    ],
    // A
    [
      [8,70],[8,16],[18,16],[18,0],[82,0],[82,16],[92,16],
      [92,70],[72,70],[72,48],[28,48],[28,70],
      [28,34],[72,34],[72,16],[28,16],[28,34],[18,34],[18,70]
    ],
    // Y
    [
      [0,0],[20,0],[20,16],[30,16],[30,28],[42,28],
      [42,16],[52,16],[52,0],[72,0],[72,36],[60,36],
      [60,70],[42,70],[42,36],[30,36],[30,70],[12,70],
      [12,36],[0,36]
    ],
    // P
    [
      [0,0],[72,0],[72,12],[82,12],[82,42],[72,42],
      [72,54],[18,54],[18,70],[0,70],
      [0,16],[18,16],[18,38],[62,38],[62,16],[18,16],[18,0]
    ]
  ]

  readonly property var widths: [92, 72, 92, 72, 82]
  readonly property real designHeight: 70
  readonly property real letterGap: 7

  readonly property real scale: Math.min(
    (width - 8) / root.designWidth,
    (height - 4) / root.designHeight
  )
  readonly property real designWidth:
    root.widths[0] + root.widths[1] + root.widths[2] +
    root.widths[3] + root.widths[4] + root.letterGap * 4

  readonly property real logoWidth: root.designWidth * root.scale
  readonly property real logoHeight: root.designHeight * root.scale
  readonly property real logoLeft: (width - root.logoWidth) / 2
  readonly property real logoTop: (height - root.logoHeight) / 2

  function drawShape(ctx, points, x, y, scale, fill) {
    ctx.fillStyle = fill
    ctx.beginPath()
    ctx.moveTo(x + points[0][0] * scale, y + points[0][1] * scale)

    for (var i = 1; i < points.length; i++)
      ctx.lineTo(
        x + points[i][0] * scale,
        y + points[i][1] * scale
      )

    ctx.closePath()
    ctx.fill()
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: false

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)

      var s = root.scale
      var extrusionX = 4.5 * s
      var extrusionY = 5.5 * s

      // Deep block extrusion.
      var x = root.logoLeft
      for (var i = 0; i < root.shapes.length; i++) {
        root.drawShape(
          ctx,
          root.shapes[i],
          x + extrusionX,
          root.logoTop + extrusionY,
          s,
          root.shadowColor
        )
        x += (root.widths[i] + root.letterGap) * s
      }

      // Main face — exactly the same accent as the clock.
      x = root.logoLeft
      for (var j = 0; j < root.shapes.length; j++) {
        root.drawShape(
          ctx,
          root.shapes[j],
          x,
          root.logoTop,
          s,
          root.color
        )
        x += (root.widths[j] + root.letterGap) * s
      }

      // Thin bright top/outer edge, echoing the reference without creating
      // another color layer across the whole face.
      var edge = Math.max(1.0, 1.25 * s)
      ctx.fillStyle = root.highlightColor

      x = root.logoLeft
      for (var k = 0; k < root.shapes.length; k++) {
        var pts = root.shapes[k]

        // Highlight only the top-facing horizontal segments.
        for (var p = 0; p < pts.length; p++) {
          var a = pts[p]
          var b = pts[(p + 1) % pts.length]

          if (Math.abs(a[1] - b[1]) < 0.01 && a[1] <= 18) {
            var hx = x + Math.min(a[0], b[0]) * s
            var hw = Math.abs(b[0] - a[0]) * s
            if (hw > 1)
              ctx.fillRect(
                hx,
                root.logoTop + a[1] * s,
                hw,
                edge
              )
          }
        }

        x += (root.widths[k] + root.letterGap) * s
      }
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