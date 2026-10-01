import QtQuick
import qs.core

// Shared section heading for popup/panel content.
// The optional leading glyph is the small TUI affordance used by revamp
// surfaces; keeping it here avoids every plugin inventing its own header.
Row {
  id: root

  property color foreground: Color.bar.text
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.caption
  property string leadingGlyph: Style.tui.headerMarker
  property string text: ""
  property bool uppercase: true

  width: parent ? parent.width : implicitWidth
  implicitWidth: (leadingText.visible ? leadingText.implicitWidth + spacing : 0) + labelText.implicitWidth
  implicitHeight: Math.max(
    leadingText.visible ? leadingText.implicitHeight : 0,
    labelText.implicitHeight
  )
  spacing: Style.spacing.sm

  Text {
    id: leadingText
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
    id: labelText
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
