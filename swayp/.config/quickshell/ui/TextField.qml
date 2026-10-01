import QtQuick
import QtQuick.Controls
import qs.core

// Single-line text input with the kit's focus + selection styling. Inherits
// from Qt Quick Controls TextField so the underlying type's API (text,
// placeholderText, accepted, editingFinished, validator, ...) is available
// to callers without re-exposing each property.
//
// Defaults bind to qs.core.Color so a caller with no theme overrides
// just works; foreground / accent / selectionTint can be overridden per
// instance. activeFocus and mouse hover / panel cursor use the same
// hover-cursor defaults, so text inputs match Button, Toggle, and Dropdown.
//
// Sizing is driven by font.pixelSize + verticalPadding. The default 30px
// implicitHeight fits dialog forms; inline callers (wifi's row-embedded
// passphrase prompt) drop verticalPadding to match a 22-26px row.
TextField {
  id: root

  property color foreground: Color.foreground
  property color accent: Color.foreground
  property color selectionTint: Style.selectionFillFor(foreground, accent)
  property bool password: false
  property real horizontalPadding: Style.spacing.controlPaddingX
  property real verticalPadding: Style.spacing.inputPaddingY

  // Panel-cursor flag. When true (and the field isn't already focused),
  // the background paints the shared hover/cursor state.
  // For mouse-enter/leave the consumer reads QQC TextField's inherited
  // `hovered` property (via onHoveredChanged) — we don't add a sibling
  // signal because the inherited property would shadow it.
  property bool hasCursor: false
  // Terminal-native inline input: no control box, only a subtle baseline.
  property bool terminalMode: false

  readonly property bool _focused: activeFocus
  readonly property bool _hot: hovered || hasCursor
  readonly property var _borderSpec: Border.controlSpec(_focused ? "focus" : (_hot ? "hover-cursor" : "normal"), root.foreground, root.accent)

  echoMode: password ? TextInput.Password : TextInput.Normal
  font.family: Style.font.family
  font.pixelSize: Style.font.body
  color: foreground
  selectionColor: selectionTint
  selectedTextColor: foreground
  placeholderTextColor: Qt.darker(foreground, 1.6)

  leftPadding: terminalMode
    ? horizontalPadding
    : horizontalPadding + Border.left(_borderSpec)
  rightPadding: terminalMode
    ? horizontalPadding
    : horizontalPadding + Border.right(_borderSpec)
  topPadding: terminalMode
    ? verticalPadding
    : verticalPadding + Border.top(_borderSpec)
  bottomPadding: terminalMode
    ? verticalPadding + Style.spacing.xs
    : verticalPadding + Border.bottom(_borderSpec)

  background: Item {
    BorderSurface {
      visible: !root.terminalMode
      anchors.fill: parent
      color: Style.controlFill(root._focused, root._hot, root.foreground, root.accent)
      borderSpec: root._borderSpec
      radius: Style.cornerRadius
    }

    Rectangle {
      visible: root.terminalMode
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 1
      color: root._focused ? root.accent : root.foreground
      opacity: root._focused ? 0.9 : 0.28
    }
  }
}
