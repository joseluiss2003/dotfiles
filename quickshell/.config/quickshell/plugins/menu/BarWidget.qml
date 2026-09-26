import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Ui
import qs.Commons

// Small square power/session launcher for the left side of the Sway bar.
// Kept under the built-in omarchy.menu id so no extra plugin registration is
// needed. It deliberately uses direct system commands instead of the Omarchy
// menu helper, which is Hyprland-oriented and was the broken leftmost applet.
BarWidget {
  id: root
  moduleName: "omarchy.menu"

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
    contentWidth: Math.min(Style.space(200), panel.availableCardWidth)
    contentHeight: Math.min(Style.space(240), panel.availableCardHeight)
    gap: Style.space(5)

    BorderSurface {
      id: card
      anchors.fill: parent
      color: Color.background
      borderSpec: Border.surfaceSpec("power-session", "card", Color.outline, Style.normalBorderWidth)
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
          height: Style.space(50)

          Row {
            anchors.left: parent.left
            anchors.leftMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            Text {
              text: "󰯙"
              color: Color.accent
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              spacing: Style.space(2)
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
                color: Color.muted
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.1
              }
            }
          }
        }

        PanelSeparator {
          width: parent.width - Style.space(20)
          x: Style.space(10)
          foreground: Color.outline
        }

        Column {
          width: parent.width
          spacing: Style.space(4)
          topPadding: Style.space(7)
          bottomPadding: Style.space(7)

          component Action: Item {
            id: action
            required property string iconText
            required property string labelText
            required property var callback
            property bool hot: false

            width: parent.width - Style.space(20)
            height: Style.space(32)
            x: Style.space(10)

            Rectangle {
              anchors.fill: parent
              color: action.hot
                ? Util.alpha(Color.text, 0.075)
                : Util.alpha(Color.surfaceAlt, 0.055)
              border.width: Style.normalBorderWidth
              border.color: action.hot
                ? Util.alpha(Color.text, 0.16)
                : Util.alpha(Color.outline, 0.18)
            }

            Rectangle {
              visible: action.hot
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: Style.space(1)
              color: Util.alpha(Color.text, 0.18)
            }

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(10)
              anchors.rightMargin: Style.space(10)
              spacing: Style.space(8)

              Text {
                width: Style.space(20)
                text: action.iconText
                color: action.labelText === "Power off"
                  ? Color.error
                  : (action.hot ? Color.text : Color.text)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.icon
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                width: parent.width - Style.space(28)
                text: action.labelText
                color: action.labelText === "Power off"
                  ? Color.error
                  : Color.text
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
