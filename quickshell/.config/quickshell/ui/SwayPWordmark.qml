import QtQuick
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth

  readonly property var logoPalette:
    Color.semanticColors && Array.isArray(Color.semanticColors.logo)
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

  function logoColor(index, fallback) {
    if (index >= 0 && index < logoPalette.length)
      return Color.colorFromValue(logoPalette[index], fallback)
    return fallback
  }

  readonly property real rowHeight: Math.max(4, height / 6)
  readonly property real fontSize: Math.max(
    4,
    Math.min(
      rowHeight * 0.92,
      (width - 8) / 58
    )
  )

  Column {
    anchors.centerIn: parent
    spacing: 0

    Repeater {
      model: root.rows

      Text {
        required property string modelData
        required property int index

        width: root.width
        height: root.rowHeight

        text: modelData
        color: root.logoColor(
          5 - index,
          index < 2 ? root.highlightColor : root.color
        )

        font.family: "monospace"
        font.pixelSize: root.fontSize
        font.weight: Font.Black
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
        lineHeightMode: Text.FixedHeight
      }
    }
  }

  Connections {
    target: Color
    function onSemanticColorsChanged() {
      root.logoPalette = Color.semanticColors && Array.isArray(Color.semanticColors.logo)
        ? Color.semanticColors.logo
        : []
    }
  }
}
