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

  function lock() { root.runAction(["loginctl", "lock-session"]) }
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
    text: "󰐥"
    opticalSize: Style.bar.iconCanvas
    fontSize: Style.bar.iconFont
    onPressed: function(b) {
      if (b === Qt.RightButton) root.logout()
      else root.popupOpen = !root.popupOpen
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(360))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(12)

      Row {
        width: parent.width
        spacing: Style.space(10)

        Text {
          text: "󰐥"
          color: Color.accent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.display
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          width: parent.width - Style.space(42)
          spacing: Style.space(2)
          anchors.verticalCenter: parent.verticalCenter

          Text {
            text: "Power"
            color: Color.text
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.heading
            font.bold: true
          }

          Text {
            text: "SESSION"
            color: Color.textMuted
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.2
          }
        }
      }

      PanelSeparator { foreground: Color.outline }

      GridLayout {
        width: parent.width
        columns: 2
        columnSpacing: Style.space(8)
        rowSpacing: Style.space(8)

        component Action: BorderSurface {
          id: action
          required property string iconText
          required property string labelText
          required property var callback
          property bool hot: false

          implicitHeight: Style.space(52)
          Layout.fillWidth: true
          color: hot ? Util.alpha(Color.accentSoft, 0.55) : Util.alpha(Color.surfaceAlt, 0.35)
          borderSpec: Border.flat(hot ? Color.accent : Util.alpha(Color.outline, 0.45), 1)

          Row {
            anchors.fill: parent
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            spacing: Style.space(10)

            Text {
              width: Style.space(24)
              text: action.iconText
              color: action.labelText === "Power off" ? Color.error : (action.hot ? Color.accent : Color.text)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.icon
              horizontalAlignment: Text.AlignHCenter
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              width: parent.width - Style.space(34)
              text: action.labelText
              color: action.labelText === "Power off" ? Color.error : Color.text
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
              font.bold: action.hot
              elide: Text.ElideRight
              anchors.verticalCenter: parent.verticalCenter
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
