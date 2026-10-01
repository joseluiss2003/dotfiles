import QtQuick
import qs.core

// Compact terminal-style status line for keyboard-driven panels.
// It keeps state and key hints in one restrained footer instead of making
// every plugin invent its own action chrome.
Column {
  id: root

  property string stateText: ""
  property var hints: []
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  width: parent ? parent.width : implicitWidth
  spacing: Style.spacing.xs

  PanelSeparator {
    id: separator
    foreground: root.foreground
    strength: 0.16
  }

  Row {
    id: statusRow
    width: parent.width
    spacing: Style.spacing.md

    Text {
      id: stateTextText
      width: Math.max(0, parent.width - hintsRow.implicitWidth - Style.spacing.md)
      textFormat: Text.PlainText
      text: root.stateText
      color: root.foreground
      opacity: 0.62
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      elide: Text.ElideRight
      verticalAlignment: Text.AlignVCenter
    }

    Row {
      id: hintsRow
      spacing: Style.spacing.md

      Repeater {
        model: root.hints

        delegate: Row {
          required property var modelData
          spacing: Style.spacing.xs

          Text {
            textFormat: Text.PlainText
            text: modelData.key || ""
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            text: String(modelData.label || "").toUpperCase()
            color: root.foreground
            opacity: 0.58
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }
      }
    }
  }
}
