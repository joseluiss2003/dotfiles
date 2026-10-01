import QtQuick
import qs.core

// CLI-style binary toggle used by compact SwayP controls.
// State is explicit text instead of a GUI switch: "● ON" / "○ OFF".
Item {
  id: root

  property bool checked: false
  property bool busy: false
  property bool interactive: true
  property bool hasCursor: false
  property bool cursorRing: interactive
  property int cursorPad: Style.space(4)
  property color foreground: Color.bar.text
  property color accent: Color.foreground

  signal toggled()
  signal hovered(bool isHovered)

  readonly property alias containsMouse: mouse.containsMouse
  readonly property bool hot: hasCursor || mouse.containsMouse
  readonly property string stateGlyph: root.checked ? Style.tui.stateOn : Style.tui.stateOff
  readonly property string stateLabel: root.checked ? "ON" : "OFF"

  implicitWidth: stateText.implicitWidth + (cursorRing ? cursorPad * 2 : 0)
  implicitHeight: Math.max(stateText.implicitHeight, Style.font.body) + (cursorRing ? cursorPad * 2 : 0)

  BorderSurface {
    anchors.fill: parent
    visible: root.cursorRing && root.hot
    color: "transparent"
    radius: Style.cornerRadius
    borderSpec: Border.controlSpec("hover-cursor", root.foreground, root.accent)
  }

  Text {
    id: stateText
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: root.stateGlyph + " " + root.stateLabel
    color: root.checked ? root.foreground : Util.alpha(root.foreground, 0.62)
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    font.bold: true

    Behavior on color { ColorAnimation { duration: 120 } }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onContainsMouseChanged: root.hovered(containsMouse)
    onClicked: if (!root.busy) root.toggled()
  }
}
