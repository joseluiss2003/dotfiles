import QtQuick
import qs.core

Item {
  id: root

  property color color: Color.foreground

  implicitWidth: 42
  implicitHeight: 42

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true

    onPaint: {
      var ctx = getContext("2d")
      var w = width
      var h = height
      var stroke = Math.max(2, Math.min(w, h) * 0.085)

      ctx.clearRect(0, 0, w, h)
      ctx.strokeStyle = root.color
      ctx.lineWidth = stroke
      ctx.lineCap = "square"
      ctx.lineJoin = "miter"

      // SwayP mark: an angular S/P monogram with the upward motion of the
      // original hand-drawn concept preserved as the defining silhouette.
      ctx.beginPath()
      ctx.moveTo(w * 0.10, h * 0.28)
      ctx.lineTo(w * 0.48, h * 0.30)
      ctx.lineTo(w * 0.76, h * 0.06)
      ctx.lineTo(w * 0.58, h * 0.29)
      ctx.lineTo(w * 0.88, h * 0.88)
      ctx.lineTo(w * 0.72, h * 0.77)
      ctx.lineTo(w * 0.46, h * 0.45)
      ctx.lineTo(w * 0.28, h * 0.78)
      ctx.lineTo(w * 0.10, h * 0.28)
      ctx.stroke()

      ctx.beginPath()
      ctx.moveTo(w * 0.46, h * 0.45)
      ctx.lineTo(w * 0.58, h * 0.29)
      ctx.stroke()
    }

    Connections {
      target: root
      function onColorChanged() { canvas.requestPaint() }
    }

    Component.onCompleted: requestPaint()
  }
}
