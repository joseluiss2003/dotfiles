import Quickshell
import QtQuick
import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 220
    height: 110

    visible: false
    color: "transparent"
    grabFocus: true

    Rectangle {
        anchors.fill: parent

        color: Theme.Theme.surface

        border.width: 1
        border.color: Theme.Theme.outline

        radius: 0

        Column {
            anchors.fill: parent
            anchors.margins: 12

            spacing: 4

            Rectangle {
                width: parent.width
                height: 36

                color: areaMouse.containsMouse
                    ? Theme.Theme.accentSoft
                    : "transparent"

                Text {
                    anchors.centerIn: parent

                    text: "󰹑  Select area"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 11
                }

                MouseArea {
                    id: areaMouse

                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: {
                        root.visible = false

                        Quickshell.execDetached([
                            "sh",
                            "-lc",
                            "grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"
                        ])
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 36

                color: fullMouse.containsMouse
                    ? Theme.Theme.accentSoft
                    : "transparent"

                Text {
                    anchors.centerIn: parent

                    text: "󰍹  Full screen"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 11
                }

                MouseArea {
                    id: fullMouse

                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: {
                        root.visible = false

                        Quickshell.execDetached([
                            "sh",
                            "-lc",
                            "grim ~/Pictures/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"
                        ])
                    }
                }
            }
        }
    }
}
