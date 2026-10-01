import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.ui
import qs.core

// SwayP session launcher. First-class popup built entirely from the shared
// panel/control system so it follows the same Quattro visual language as the
// other shell popups.
BarWidget {
  id: root
  moduleName: "swayp.menu"

  property bool popupOpen: false
  property int selectedIndex: 0
  property bool cursorActive: false
  readonly property var sessionActions: [
    { label: "LOCK" },
    { label: "SUSPEND" },
    { label: "LOG OUT" },
    { label: "REBOOT" },
    { label: "POWER OFF" }
  ]

  function close() {
    popupOpen = false
  }

  function runAction(command) {
    root.popupOpen = false
    Quickshell.execDetached(command)
  }

  function lock() { root.runAction(["qs", "ipc", "call", "lock", "lock"]) }
  function suspend() { root.runAction(["systemctl", "suspend"]) }
  function logout() { root.runAction(["swaymsg", "exit"]) }
  function reboot() { root.runAction(["systemctl", "reboot"]) }
  function poweroff() { root.runAction(["systemctl", "poweroff"]) }

  function activateAction(index) {
    if (index === 0) root.lock()
    else if (index === 1) root.suspend()
    else if (index === 2) root.logout()
    else if (index === 3) root.reboot()
    else if (index === 4) root.poweroff()
  }

  function moveAction(delta) {
    var next = selectedIndex + delta
    if (next < 0) next = 0
    if (next > 4) next = 4
    selectedIndex = next
    cursorActive = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰐥"
    fontSize: Style.bar.iconFont
    opticalSize: Style.bar.iconCanvas
    onPressed: function(b) {
      if (b === Qt.RightButton) root.logout()
      else root.popupOpen = !root.popupOpen
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.popupOpen
    keyboardEnabled: false
    backgroundColor: Color.popups.background
    contentWidth: panel.fittedContentWidth(Style.space(250))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) {
          root.cursorActive = true
          return
        }
        if (dy !== 0) root.moveAction(dy > 0 ? 1 : -1)
      }

      onActivateRequested: {
        if (root.cursorActive) root.activateAction(root.selectedIndex)
        else root.cursorActive = true
      }

      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.spacing.panelGap

        PanelCliHeader {
          title: "Power & Session"
          status: "SESSION"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
        }

PanelSectionHeader {
          text: "SESSION"
          leadingGlyph: Icons.power
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
        }

        Repeater {
          model: root.sessionActions

            Item {
              id: sessionRow
              required property var modelData
              required property int index

              width: parent.width
              height: sessionLabel.implicitHeight

              CursorSurface {
                anchors.fill: parent
                hasCursor: root.cursorActive && root.selectedIndex === index
                current: false
                foreground: root.bar.foreground
                fill: "transparent"
                currentFill: "transparent"
                implicitHeight: sessionLabel.implicitHeight

                Text {
                  id: sessionLabel
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.leftMargin: Style.spacing.sectionGap + Style.spacing.md
                  anchors.rightMargin: Style.spacing.sectionGap + Style.spacing.md
                  anchors.verticalCenter: parent.verticalCenter
                  textFormat: Text.PlainText
                  text: modelData.label
                  color: index === 4 ? Color.error : root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: index === 4
                  elide: Text.ElideRight
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  onContainsMouseChanged: if (containsMouse) {
                    root.cursorActive = true
                    root.selectedIndex = index
                  }
                  onClicked: root.activateAction(index)
                }
              }
            }
        }
      }
    }
  }

  onPopupOpenChanged: {
    if (popupOpen) {
      selectedIndex = 0
      cursorActive = false
    } else {
      cursorActive = false
    }
  }
}
