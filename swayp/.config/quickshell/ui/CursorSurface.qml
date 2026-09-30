import QtQuick
import qs.core

// Shared visual chrome for keyboard-and-mouse-navigable items inside a panel.
// Contract: items must NOT read `containsMouse` for color/border. Mouse
// hover updates the panel's cursor state at the root; visuals derive from
// `hasCursor` / `current`. That's what guarantees a single highlight on
// screen at any time across both keyboard and mouse interaction.
//
// Cursor paint is always the shared hover-cursor fill plus optional
// hover-cursor border. `outline` remains as a compatibility flag for
// callers that used to request border-only rows, but slider rows still
// receive the same hover-cursor background as every other row.
BorderSurface {
  id: root

  property bool hasCursor: false
  property bool current: false
  property bool outline: false
  property bool bordered: false
  // TUI cursor marker: selection is readable even when a theme uses a very
  // subtle fill/border. It is painted out of flow so it never changes row size.
  property bool showCursorMarker: true
  property string cursorMarker: Style.tui.cursorMarker
  property color cursorMarkerColor: accent

  property color foreground: Color.bar.text
  property color accent: Color.accent
  property color fill: Style.hoverFillFor(foreground, accent)
  property color currentFill: Style.selectedAccentFill

  radius: Style.cornerRadius

  color: hasCursor ? fill : (current ? currentFill : "transparent")

  Text {
    visible: root.showCursorMarker && root.hasCursor && root.cursorMarker !== ""
    textFormat: Text.PlainText
    text: root.cursorMarker
    color: root.cursorMarkerColor
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    font.bold: true
    anchors.left: parent.left
    anchors.leftMargin: Style.spacing.xs
    anchors.verticalCenter: parent.verticalCenter
    z: 10
  }
  borderSpec: root.hasCursor
    ? Border.controlSpec("hover-cursor", root.foreground, root.accent)
    : (root.current
      ? Border.controlSpec("selected", root.foreground, root.accent)
      : (root.bordered
        ? Border.controlSpec("normal", root.foreground, root.accent)
        : Border.none()))

  Behavior on color {
    ColorAnimation { duration: 60 }
  }
}
