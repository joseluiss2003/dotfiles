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
  property int tick: 0
  property int updateDelay: 4

  // CMatrix uses the printable ASCII range by default.
  function randomGlyph() {
    return String.fromCharCode(33 + Math.floor(Math.random() * 90))
  }

  function randomLength(rows) {
    return 3 + Math.floor(Math.random() * Math.max(1, rows - 2))
  }

  function newColumn(rows) {
    var streamLength = randomLength(rows)
    var chars = []

    for (var i = 0; i < streamLength; i++)
      chars.push(randomGlyph())

    return {
      head: -1,
      length: streamLength,
      spaces: 1 + Math.floor(Math.random() * rows),
      update: 1 + Math.floor(Math.random() * 3),
      chars: chars
    }
  }

  function resetColumns() {
    var rows = Math.max(4, Math.floor(matrixCanvas.height / cellHeight))
    var count = Math.max(1, Math.floor(matrixCanvas.width / cellWidth))
    var next = []

    for (var i = 0; i < count; i++) {
      var column = newColumn(rows)

      // Stagger the initial streams, like cmatrix's spaces[] state.
      column.head = -column.spaces - 1
      next.push(column)
    }

    tick = 0
    columns = next
    matrixCanvas.requestPaint()
  }

  function advance() {
    var rows = Math.max(4, Math.floor(matrixCanvas.height / cellHeight))
    var next = []

    tick++
    if (tick > 4)
      tick = 1

    for (var i = 0; i < columns.length; i++) {
      var column = columns[i]

      // Per-column update cadence corresponds to cmatrix's updates[].
      if (tick <= column.update) {
        next.push(column)
        continue
      }

      var head = column.head
      var chars = column.chars.slice()

      if (head < 0) {
        head++
      } else {
        head++

        // Grow the stream at the head; once it reaches its configured
        // length, the oldest cell falls away from the tail.
        chars.push(randomGlyph())
        if (chars.length > column.length)
          chars.shift()
      }

      // The complete stream has left the screen: respawn after a new gap.
      if (head - column.length > rows) {
        var replacement = newColumn(rows)
        replacement.head = -replacement.spaces - 1
        next.push(replacement)
      } else {
        next.push({
          head: head,
          length: column.length,
          spaces: column.spaces,
          update: column.update,
          chars: chars
        })
      }
    }

    columns = next
    matrixCanvas.requestPaint()
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
          clip: true

          onWidthChanged: root.resetColumns()
          onHeightChanged: root.resetColumns()

          onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.font = matrixFontSize + "px '" + Style.font.family + "'"
            ctx.textBaseline = "top"

            var rows = Math.max(4, Math.floor(height / cellHeight))

            for (var xIndex = 0; xIndex < root.columns.length; xIndex++) {
              var column = root.columns[xIndex]
              var x = xIndex * cellWidth

              if (x >= width)
                continue

              var first = Math.max(0, column.head - column.length + 1)
              var last = Math.min(rows - 1, column.head)

              for (var row = first; row <= last; row++) {
                var bodyIndex = row - (column.head - column.length + 1)

                if (bodyIndex < 0 || bodyIndex >= column.chars.length)
                  continue

                ctx.fillStyle = row === column.head
                  ? Color.foreground
                  : Color.accent

                ctx.fillText(column.chars[bodyIndex], x, row * cellHeight)
              }
            }
          }
        }
      }

      // CMatrix defaults to update delay 4 => 40 ms simulation ticks.
      Timer {
        interval: root.updateDelay * 10
        repeat: true
        running: true
        onTriggered: root.advance()
      }

      Component.onCompleted: root.resetColumns()
    }
  }
}
