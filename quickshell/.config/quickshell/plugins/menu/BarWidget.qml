import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.ui
import qs.core

// Small square power/session launcher for the left side of the Sway bar.
// Uses the built-in swayp.menu id so it participates in the normal plugin registry without
// special menu dependencies. It deliberately uses direct system commands instead of external Omarchy
// menu helper, which is Hyprland-oriented and was the broken leftmost applet.
BarWidget {
  id: root
  moduleName: "swayp.menu"

  property bool popupOpen: false

  function close() { popupOpen = false }

  function runAction(command) {
    root.popupOpen = false
    Quickshell.execDetached(command)
  }

  function lock() { root.runAction(["qs", "ipc", "call", "lock", "lock"]) }
  function suspend() { root.runAction(["systemctl", "suspend"]) }
  function logout() { root.runAction(["swaymsg", "exit"]) }
  function reboot() { root.runAction(["systemctl", "reboot"]) }
  function poweroff() { root.runAction(["systemctl", "poweroff"]) }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰯙"
    opticalSize: Style.bar.iconCanvas
    fontSize: Style.bar.iconFont
    onPressed: function(b) {
      if (b === Qt.RightButton) root.logout()
      else root.popupOpen = !root.popupOpen
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    focusTarget: keyCatcher
    padding: 0
    borderSpec: Border.surfaceSpec("power-session", "panel-wrapper", "transparent", 0)
    contentWidth: Math.min(Style.popup.compactPopupWidth, panel.availableCardWidth)
    contentHeight: Math.min(Style.popup.compactPopupHeight, panel.availableCardHeight)
    gap: Style.popup.gap
    // This plugin owns its own card surface below. Do not let KeyboardPanel
    // draw a second copy of the popup background underneath it.
    drawBackground: false

    BorderSurface {
      id: card
      anchors.fill: parent
      // Use the same shell surface as every other popup; Color.background is
      // the deeper base surface and made this session card look opaque.
      color: Color.popups.background
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Style.popup.borderWidth)
      radius: 0
      clip: true

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
      }

      Column {
        anchors.fill: parent
        spacing: 0

        Item {
          width: parent.width
          height: Style.popup.headerHeight

          Row {
            anchors.left: parent.left
            anchors.leftMargin: Style.popup.contentInset
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.controlGap

            SwayPMark {
              width: 34
              height: 34
              color: Color.accent
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              spacing: Style.spacing.compactGap
              anchors.verticalCenter: parent.verticalCenter

              Text {
                text: "Power"
                color: Color.text
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                text: "SESSION"
                color: Color.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.1
              }
            }
          }
        }

        PanelSeparator {
          width: parent.width - Style.spacing.wideGap
          x: Style.popup.contentInset
          foreground: Color.foreground
        }

        Column {
          width: parent.width
          spacing: Style.spacing.sm
          topPadding: Style.spacing.sm
          bottomPadding: Style.spacing.sm

          component Action: Item {
            id: action
            required property string iconText
            required property string labelText
            required property var callback
            property bool hot: false

            width: parent.width - Style.spacing.wideGap
            height: Style.popup.actionHeight
            x: Style.popup.contentInset

            Rectangle {
              anchors.fill: parent
              color: action.hot
                ? Color.controls.hoverBackground
                : Util.alpha(Color.controls.background, 0.35)
              border.width: Style.normalBorderWidth
              border.color: action.hot
                ? Color.controls.selectedBorder
                : Color.controls.border
            }

            Rectangle {
              visible: action.hot
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: Style.space(1)
              color: Color.controls.selectedBorder
            }

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.popup.contentInset
              anchors.rightMargin: Style.popup.contentInset
              spacing: Style.spacing.controlGap

              Text {
                width: Style.spacing.wideGap
                text: action.iconText
                color: action.labelText === "Power off"
                  ? Color.controls.danger
                  : Color.controls.text
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.icon
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                width: parent.width - Style.space(28)
                text: action.labelText
                color: action.labelText === "Power off"
                  ? Color.controls.danger
                  : Color.controls.text
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: false
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: action.hot = true
              onExited: action.hot = false
              onClicked: action.callback()
            }
          }

          Action { iconText: "󰌾"; labelText: "Lock"; callback: root.lock }
          Action { iconText: "󰒲"; labelText: "Suspend"; callback: root.suspend }
          Action { iconText: "󰍃"; labelText: "Log out"; callback: root.logout }
          Action { iconText: "󰜉"; labelText: "Reboot"; callback: root.reboot }
          Action { iconText: "⏻"; labelText: "Power off"; callback: root.poweroff }
        }
      }
    }
  }
}
