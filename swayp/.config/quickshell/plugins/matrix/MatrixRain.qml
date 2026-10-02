import QtQuick
import qs.core

Item {
  id: root

  property int fontSize: Math.max(11, Style.fontPx(0.98))
  property int cellWidth: Math.max(8, Math.round(fontSize * 0.72))
  property int cellHeight: Math.max(12, Math.round(fontSize * 1.02))
  property int updateDelay: 8
  property real density: 1.0
  property color glyphColor: Color.success
  property real glyphOpacity: 1.0
  property var columns: []
  property int tick: 0

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
    var rows = Math.max(4, Math.floor(height / cellHeight))
    var count = Math.max(1, Math.floor(width / (cellWidth / Math.max(0.5, root.density))))
    var next = []

    for (var i = 0; i < count; i++) {
      var column = newColumn(rows)
      column.head = -column.spaces - 1
      next.push(column)
    }

    tick = 0
    columns = next
  }

  function advance() {
    var rows = Math.max(4, Math.floor(height / cellHeight))
    var next = []

    tick++
    if (tick > 4)
      tick = 1

    for (var i = 0; i < columns.length; i++) {
      var column = columns[i]

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
        chars.push(randomGlyph())

        if (chars.length > column.length)
          chars.shift()
      }

      if (head - column.length > rows) {
        next.push(newColumn(rows))
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
  }

  Canvas {
    id: matrixCanvas
    anchors.fill: parent
    clip: true

    onWidthChanged: {
      root.resetColumns()
      requestPaint()
    }

    onHeightChanged: {
      root.resetColumns()
      requestPaint()
    }

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      ctx.font = root.fontSize + "px '" + Style.font.family + "'"
      ctx.textBaseline = "top"
      ctx.globalAlpha = root.glyphOpacity

      var rows = Math.max(4, Math.floor(height / root.cellHeight))

      for (var xIndex = 0; xIndex < root.columns.length; xIndex++) {
        var column = root.columns[xIndex]
        var x = xIndex * root.cellWidth

        if (x >= width)
          continue

        var first = Math.max(0, column.head - column.length + 1)
        var last = Math.min(rows - 1, column.head)

        for (var row = first; row <= last; row++) {
          var bodyIndex = row - (column.head - column.length + 1)

          if (bodyIndex < 0 || bodyIndex >= column.chars.length)
            continue

          ctx.fillStyle = root.glyphColor
          ctx.fillText(column.chars[bodyIndex], x, row * root.cellHeight)
        }
      }
    }
  }

  Timer {
    interval: root.updateDelay * 10
    repeat: true
    running: root.width > 0 && root.height > 0
    onTriggered: {
      root.advance()
      matrixCanvas.requestPaint()
    }
  }

  Component.onCompleted: {
    resetColumns()
    matrixCanvas.requestPaint()
  }
}
