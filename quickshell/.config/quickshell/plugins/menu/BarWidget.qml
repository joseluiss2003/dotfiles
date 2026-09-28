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
    text: ""
    iconComponent: Component {
      SwayPMark {
        anchors.fill: parent
        color: Color.brand.foreground
      }
    }
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
    contentWidth: Math.min(Style.space(430), panel.availableCardWidth)
    contentHeight: Math.min(Style.space(400), panel.availableCardHeight)
    gap: 0
    drawBackground: false

    BorderSurface {
      id: card
      anchors.fill: parent
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
          height: Style.space(74)

          Row {
            anchors.left: parent.left
            anchors.leftMargin: Style.popup.contentInset
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.popup.sectionGap

            Rectangle {
              width: Style.space(46)
              height: width
              color: Util.alpha(Color.brand.accent, 0.12)
              border.width: Style.normalBorderWidth
              border.color: Util.alpha(Color.brand.accent, 0.35)
              anchors.verticalCenter: parent.verticalCenter

              SwayPMark {
                anchors.centerIn: parent
                width: Style.space(30)
                height: Style.space(30)
                color: Color.brand.accent
              }
            }

            Column {
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.spacing.compactGap

              Text {
                text: "Session"
                color: Color.text
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                text: "POWER & SESSION"
                color: Color.muted
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.1
              }
            }
          }

          Text {
            anchors.right: parent.right
            anchors.rightMargin: Style.popup.contentInset
            anchors.verticalCenter: parent.verticalCenter
            text: "ESC"
            color: Color.muted
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 0.8
          }
        }

        PanelSeparator {
          width: parent.width - (Style.popup.contentInset * 2)
          x: Style.popup.contentInset
          foreground: Color.outline
        }

        Grid {
          width: parent.width - (Style.popup.contentInset * 2)
          x: Style.popup.contentInset
          topPadding: Style.spacing.sm
          bottomPadding: Style.spacing.sm
          columns: 2
          columnSpacing: Style.spacing.sm
          rowSpacing: Style.spacing.sm

          component Action: BorderSurface {
            id: action
            required property string iconText
            required property string labelText
            required property string descriptionText
            required property var callback
            property bool hot: false
            property bool destructive: labelText === "Power off" || labelText === "Log out"

            width: (parent.width - parent.columnSpacing) / 2
            height: Style.space(78)
            radius: 0
            color: action.hot
              ? Color.controls.hoverBackground
              : Util.alpha(Color.controls.background, 0.20)
            borderSpec: Border.surfaceSpec(
              "power-session",
              action.hot ? "selected" : "action",
              action.hot ? Color.controls.selectedBorder : Color.controls.border,
              Style.normalBorderWidth
            )

            Behavior on color {
              ColorAnimation { duration: 140; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
              NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            scale: action.hot ? 1.015 : 1.0

            Rectangle {
              visible: action.hot
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: Style.space(2)
              color: action.destructive ? Color.controls.danger : Color.controls.selectedBorder
            }

            Column {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.popup.contentInset
              anchors.rightMargin: Style.popup.contentInset
              spacing: Style.spacing.compactGap

              Row {
                width: parent.width
                spacing: Style.spacing.controlGap

                Text {
                  text: action.iconText
                  color: action.destructive
                    ? Color.controls.danger
                    : (action.hot ? Color.controls.selectedText : Color.controls.text)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.iconLarge
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: action.labelText
                  color: action.destructive
                    ? Color.controls.danger
                    : (action.hot ? Color.controls.selectedText : Color.controls.text)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.heading
                  font.bold: action.hot
                  anchors.verticalCenter: parent.verticalCenter
                  elide: Text.ElideRight
                }
              }

              Text {
                width: parent.width
                text: action.descriptionText
                color: action.hot ? Color.controls.selectedText : Color.muted
                opacity: action.hot ? 0.82 : 0.72
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
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

          Action { iconText: "󰌾"; labelText: "Lock"; descriptionText: "Secure your session"; callback: root.lock }
          Action { iconText: "󰒲"; labelText: "Suspend"; descriptionText: "Sleep the computer"; callback: root.suspend }
          Action { iconText: "󰍃"; labelText: "Log out"; descriptionText: "End the current session"; callback: root.logout }
          Action { iconText: "󰜉"; labelText: "Reboot"; descriptionText: "Restart the system"; callback: root.reboot }
          Action { iconText: "⏻"; labelText: "Power off"; descriptionText: "Shut down the computer"; callback: root.poweroff }
        }

        Item {
          width: parent.width
          height: Style.space(28)

          Text {
            anchors.centerIn: parent
            text: "Select an action"
            color: Color.muted
            opacity: 0.65
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
  }
}
