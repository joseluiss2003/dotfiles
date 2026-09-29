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
    contentWidth: panel.fittedContentWidth(Style.space(350))
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

        // Compact hero: the popup identifies itself immediately without
        // spending a full section on decorative text.
        Item {
          width: parent.width
          implicitHeight: Style.space(48)

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
              color: root.bar.foreground
              opacity: 0.58
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.0
            }
          }
        }

        PanelSeparator {
          foreground: root.bar.foreground
          opacity: 0.42
        }

        // The Quattro-style rhythm is intentionally compact: paired actions
        // carry equal visual weight while the destructive action gets its own
        // full-width row.
        Column {
          width: parent.width
          spacing: Style.spacing.controlGap

          Row {
            width: parent.width
            spacing: Style.spacing.controlGap

            Button {
              width: (parent.width - parent.spacing) / 2
              height: Style.space(52)
              iconText: "󰌾"
              text: "Lock"
              iconSize: Style.font.icon
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              accent: root.bar.foreground
              hasCursor: root.cursorActive && root.selectedIndex === 0
              selectionBorderOnly: true
              onClicked: root.lock()
              onHovered: function(h) {
                if (h) {
                  root.cursorActive = true
                  root.selectedIndex = 0
                }
              }
            }

            Button {
              width: (parent.width - parent.spacing) / 2
              height: Style.space(52)
              iconText: "󰒲"
              text: "Suspend"
              iconSize: Style.font.icon
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              accent: root.bar.foreground
              hasCursor: root.cursorActive && root.selectedIndex === 1
              selectionBorderOnly: true
              onClicked: root.suspend()
              onHovered: function(h) {
                if (h) {
                  root.cursorActive = true
                  root.selectedIndex = 1
                }
              }
            }
          }

          Row {
            width: parent.width
            spacing: Style.spacing.controlGap

            Button {
              width: (parent.width - parent.spacing) / 2
              height: Style.space(52)
              iconText: "󰍃"
              text: "Log out"
              iconSize: Style.font.icon
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              accent: root.bar.foreground
              hasCursor: root.cursorActive && root.selectedIndex === 2
              selectionBorderOnly: true
              onClicked: root.logout()
              onHovered: function(h) {
                if (h) {
                  root.cursorActive = true
                  root.selectedIndex = 2
                }
              }
            }

            Button {
              width: (parent.width - parent.spacing) / 2
              height: Style.space(52)
              iconText: "󰜉"
              text: "Reboot"
              iconSize: Style.font.icon
              fontSize: Style.font.bodySmall
              foreground: root.bar.foreground
              accent: root.bar.foreground
              hasCursor: root.cursorActive && root.selectedIndex === 3
              selectionBorderOnly: true
              onClicked: root.reboot()
              onHovered: function(h) {
                if (h) {
                  root.cursorActive = true
                  root.selectedIndex = 3
                }
              }
            }
          }

          Button {
            width: parent.width
            height: Style.space(46)
            leftAlign: true
            iconText: "󰐥"
            text: "Power off"
            iconSize: Style.font.icon
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            accent: Color.error
            hasCursor: root.cursorActive && root.selectedIndex === 4
            selectionBorderOnly: true
            onClicked: root.poweroff()
            onHovered: function(h) {
              if (h) {
                root.cursorActive = true
                root.selectedIndex = 4
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
