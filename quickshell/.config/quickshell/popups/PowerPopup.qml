import Quickshell
import QtQuick

import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 240
    height: 210

    visible: false
    color: "transparent"
    grabFocus: true

    function run(command) {
        Quickshell.execDetached([
            "sh",
            "-lc",
            command
        ])

        root.visible = false
    }

    Rectangle {
        anchors.fill: parent

        color: Theme.Theme.surface
        border.width: 1
        border.color: Theme.Theme.outline
        radius: 0

        Column {
            anchors.fill: parent
            anchors.margins: 12

            spacing: 2

            Text {
                leftPadding: 8
                text: "POWER"

                color: Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 10
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 38

                color: lockMouse.containsMouse
                    ? Theme.Theme.accentSoft
                    : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8

                    text: "󰌾  Lock"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: lockMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        root.run(
                            "loginctl lock-session"
                        )
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 38

                color: logoutMouse.containsMouse
                    ? Theme.Theme.accentSoft
                    : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8

                    text: "󰍃  Logout"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: logoutMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        root.run(
                            "swaymsg exit"
                        )
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 38

                color: rebootMouse.containsMouse
                    ? Theme.Theme.accentSoft
                    : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8

                    text: "󰜉  Reboot"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: rebootMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        root.run(
                            "systemctl reboot"
                        )
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 38

                color: shutdownMouse.containsMouse
                    ? Theme.Theme.accentSoft
                    : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8

                    text: "󰐥  Shutdown"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: shutdownMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        root.run(
                            "systemctl poweroff"
                        )
                    }
                }
            }
        }
    }
}
