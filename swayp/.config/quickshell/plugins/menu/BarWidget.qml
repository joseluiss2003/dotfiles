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
    { label: "LOCK", icon: "󰌾" },
    { label: "SUSPEND", icon: "󰒲" },
    { label: "LOG OUT", icon: "󰍃" },
    { label: "REBOOT", icon: "󰜉" },
    { label: "POWER OFF", icon: "󰐥" }
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
    contentWidth: panel.fittedContentWidth(Style.space(290))
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

        // Compact hero: same grammar as the other SwayP panels.
        Item {
          width: parent.width
          implicitHeight: Math.max(heroMark.implicitHeight, heroLabels.implicitHeight)

          OpticalGlyph {
            id: heroMark
            width: Style.space(34)
            height: Style.space(34)
            text: "󰐥"
            color: root.bar.foreground
            fontFamily: root.bar.fontFamily
            fontSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroMark.right
            anchors.leftMargin: Style.spacing.panelGap
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.xs

            Text {
              text: "Power & Session"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }

            Text {
              text: "SYSTEM SESSION"
              color: Color.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }
        }

        PanelSeparator {
          foreground: root.bar.foreground
          opacity: 0.32
        }

        PanelSectionHeader {
          text: "SESSION"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
        }

        Column {
          width: parent.width
          spacing: Style.spacing.xs

          Repeater {
            model: root.sessionActions

            Item {
              id: sessionRow
              required property var modelData
              required property int index

              width: parent.width
              height: Style.space(30)

              CursorSurface {
                anchors.fill: parent
                hasCursor: root.cursorActive && root.selectedIndex === index
                foreground: root.bar.foreground
                fill: "transparent"
                currentFill: "transparent"

                Text {
                  textFormat: Text.PlainText
                  text: modelData.label
                  color: index === 4 ? Color.error : root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: index === 4
                  anchors.left: parent.left
                  anchors.leftMargin: Style.spacing.md + Style.spacing.md
                  anchors.verticalCenter: parent.verticalCenter
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

        PanelStatusLine {
          stateText: "SYSTEM SESSION"
          foreground: root.bar.foreground
          accent: Color.accent
          fontFamily: root.bar.fontFamily
          hints: [
            { key: "↑↓", label: "NAV" },
            { key: "ENTER", label: "SELECT" },
            { key: "ESC", label: "CLOSE" }
          ]
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
