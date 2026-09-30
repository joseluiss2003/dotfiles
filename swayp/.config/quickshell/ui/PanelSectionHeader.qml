import QtQuick
import qs.core
import qs.ui

// Shared section heading for popup/panel content.
// The optional leading glyph is the small TUI affordance used by revamp
// surfaces; keeping it here avoids every plugin inventing its own header.
Row {
  id: root

  property color foreground: Color.bar.text
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.caption
  property string leadingGlyph: ""
  property bool uppercase: true

  spacing: Style.spacing.sm

  Text {
    visible: root.leadingGlyph !== ""
    textFormat: Text.PlainText
    text: root.leadingGlyph
    color: root.accent
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.bold: true
    verticalAlignment: Text.AlignVCenter
    topPadding: Math.ceil(root.fontSize * 0.15)
  }

  Text {
    textFormat: Text.PlainText
    text: root.uppercase ? String(root.text).toUpperCase() : root.text
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.bold: true
    verticalAlignment: Text.AlignVCenter
    topPadding: Math.ceil(root.fontSize * 0.15)
  }
}
