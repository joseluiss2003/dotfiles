import Quickshell
import QtQuick
import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 240
    height: 250

    visible: false
    color: "transparent"
    grabFocus: true
    Rectangle {
        anchors.fill: parent

        color: Qt.rgba(
            Theme.Theme.background.r,
            Theme.Theme.background.g,
            Theme.Theme.background.b,
            0.97
        )

        border.width: 1

        border.color: Qt.rgba(
            Theme.Theme.outline.r,
            Theme.Theme.outline.g,
            Theme.Theme.outline.b,
            0.75
        )

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Rectangle {
                width: parent.width
                height: 42

                color: Qt.rgba(
                    Theme.Theme.accent.r,
                    Theme.Theme.accent.g,
                    Theme.Theme.accent.b,
                    0.10
                )

                border.width: 1
                border.color: Qt.rgba(
                    Theme.Theme.accent.r,
                    Theme.Theme.accent.g,
                    Theme.Theme.accent.b,
                    0.22
                )

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: ""

                        color: Theme.Theme.accent

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 20
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Text {
                            text: "SYSTEM"

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            text: "Power & session"

                            color: Theme.Theme.textMuted

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 9
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1

                color: Qt.rgba(
                    Theme.Theme.outline.r,
                    Theme.Theme.outline.g,
                    Theme.Theme.outline.b,
                    0.30
                )
            }

            Rectangle {
                width: parent.width
                height: 34

                color: logoutMouse.containsMouse
                    ? Qt.rgba(
                        Theme.Theme.accent.r,
                        Theme.Theme.accent.g,
                        Theme.Theme.accent.b,
                        0.16
                    )
                    : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "󰍁"

                        color: logoutMouse.containsMouse
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 17
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Cerrar sesión"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: logoutMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        root.visible = false

                        Quickshell.execDetached([
                            "swaymsg",
                            "exit"
                        ])
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 34

                color: suspendMouse.containsMouse
                    ? Qt.rgba(
                        Theme.Theme.accent.r,
                        Theme.Theme.accent.g,
                        Theme.Theme.accent.b,
                        0.16
                    )
                    : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "󰒲"

                        color: suspendMouse.containsMouse
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 17
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Suspender"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: suspendMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        root.visible = false

                        Quickshell.execDetached([
                            "systemctl",
                            "suspend"
                        ])
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 34

                color: rebootMouse.containsMouse
                    ? Qt.rgba(
                        Theme.Theme.accent.r,
                        Theme.Theme.accent.g,
                        Theme.Theme.accent.b,
                        0.16
                    )
                    : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "󰜉"

                        color: rebootMouse.containsMouse
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 17
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Reiniciar"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: rebootMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        root.visible = false

                        Quickshell.execDetached([
                            "systemctl",
                            "reboot"
                        ])
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 34

                color: poweroffMouse.containsMouse
                    ? Qt.rgba(
                        Theme.Theme.error.r,
                        Theme.Theme.error.g,
                        Theme.Theme.error.b,
                        0.18
                    )
                    : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "󰐥"

                        color: poweroffMouse.containsMouse
                            ? Theme.Theme.error
                            : Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 17
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Apagar"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: poweroffMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        root.visible = false

                        Quickshell.execDetached([
                            "systemctl",
                            "poweroff"
                        ])
                    }
                }
            }
        }
    }
}

