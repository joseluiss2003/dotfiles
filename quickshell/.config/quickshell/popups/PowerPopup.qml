import Quickshell
import QtQuick

import "../generated" as Theme

PopupWindow {
    id: root

    property Item anchorItem
    property bool confirmAction: false
    property string pendingAction: ""

    visible: false

    implicitWidth: 190
    implicitHeight: confirmAction ? 176 : 208

    color: "transparent"

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Top | Edges.Left

    grabFocus: true

    onVisibleChanged: {
        if (!visible) {
            confirmAction = false
            pendingAction = ""
        }
    }

    function accent(alpha) {
        return Qt.rgba(
            Theme.Theme.accent.r,
            Theme.Theme.accent.g,
            Theme.Theme.accent.b,
            alpha
        )
    }

    function textMuted(alpha) {
        return Qt.rgba(
            Theme.Theme.textMuted.r,
            Theme.Theme.textMuted.g,
            Theme.Theme.textMuted.b,
            alpha
        )
    }

    function runAction(action) {
        root.visible = false

        if (action === "lock") {
            Quickshell.execDetached([
                "hyprlock"
            ])
            return
        }

        if (action === "logout") {
            Quickshell.execDetached([
                "swaymsg",
                "exit"
            ])
            return
        }

        if (action === "restart") {
            Quickshell.execDetached([
                "systemctl",
                "reboot"
            ])
            return
        }

        if (action === "shutdown") {
            Quickshell.execDetached([
                "systemctl",
                "poweroff"
            ])
        }
    }

    function askConfirmation(action) {
        confirmAction = true
        pendingAction = action
    }

    function executePendingAction() {
        if (pendingAction.length === 0)
            return

        var action = pendingAction

        confirmAction = false
        pendingAction = ""

        runAction(action)
    }

    Rectangle {
        anchors.fill: parent

        color: Theme.Theme.background

        border.width: 2
        border.color: Theme.Theme.accent
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10

        spacing: 6

        Text {
            width: parent.width

            text: confirmAction ? "CONFIRM POWER ACTION" : "POWER"

            color: Theme.Theme.accent

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 9
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: 1

            color: accent(0.35)
        }

        Item {
            width: parent.width
            height: confirmAction ? 70 : 156

            Column {
                anchors.fill: parent

                spacing: 4

                visible: !root.confirmAction

                Item {
                    width: parent.width
                    height: 36

                    Rectangle {
                        anchors.fill: parent

                        color: lockMouse.containsMouse
                            ? accent(0.12)
                            : "transparent"

                        border.width: lockMouse.containsMouse ? 1 : 0
                        border.color: accent(0.80)
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: "󰌾"

                            color: Theme.Theme.accent

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 16
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: "LOCK"

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: lockMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: root.runAction("lock")
                    }
                }

                Item {
                    width: parent.width
                    height: 36

                    Rectangle {
                        anchors.fill: parent

                        color: logoutMouse.containsMouse
                            ? accent(0.12)
                            : "transparent"

                        border.width: logoutMouse.containsMouse ? 1 : 0
                        border.color: accent(0.80)
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: "󰍃"

                            color: Theme.Theme.accent

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 16
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: "LOGOUT"

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: logoutMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: root.runAction("logout")
                    }
                }

                Item {
                    width: parent.width
                    height: 36

                    Rectangle {
                        anchors.fill: parent

                        color: restartMouse.containsMouse
                            ? accent(0.12)
                            : "transparent"

                        border.width: restartMouse.containsMouse ? 1 : 0
                        border.color: accent(0.80)
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: "󰜉"

                            color: Theme.Theme.accent

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 16
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: "RESTART"

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: restartMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: root.askConfirmation("restart")
                    }
                }

                Item {
                    width: parent.width
                    height: 36

                    Rectangle {
                        anchors.fill: parent

                        color: shutdownMouse.containsMouse
                            ? accent(0.12)
                            : "transparent"

                        border.width: shutdownMouse.containsMouse ? 1 : 0
                        border.color: accent(0.80)
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        spacing: 12

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: "󰐥"

                            color: Theme.Theme.accent

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 16
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: "SHUTDOWN"

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: shutdownMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: root.askConfirmation("shutdown")
                    }
                }
            }

            Column {
                anchors.fill: parent

                spacing: 8

                visible: root.confirmAction

                Text {
                    width: parent.width

                    text: root.pendingAction === "restart"
                        ? "Restart the system?"
                        : "Shut down the system?"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                }

                Text {
                    width: parent.width

                    text: "Click CONFIRM to continue."

                    color: Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 8
                }

                Row {
                    width: parent.width
                    height: 34

                    spacing: 5

                    Item {
                        width: (parent.width - 5) / 2
                        height: 34

                        Rectangle {
                            anchors.fill: parent

                            color: cancelMouse.containsMouse
                                ? accent(0.12)
                                : "transparent"

                            border.width: 1
                            border.color: cancelMouse.containsMouse
                                ? Theme.Theme.accent
                                : accent(0.35)
                        }

                        Text {
                            anchors.centerIn: parent

                            text: "CANCEL"

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 8
                            font.bold: true
                        }

                        MouseArea {
                            id: cancelMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                root.confirmAction = false
                                root.pendingAction = ""
                            }
                        }
                    }

                    Item {
                        width: (parent.width - 5) / 2
                        height: 34

                        Rectangle {
                            anchors.fill: parent

                            color: confirmMouse.containsMouse
                                ? accent(0.20)
                                : accent(0.08)

                            border.width: 1
                            border.color: Theme.Theme.accent
                        }

                        Text {
                            anchors.centerIn: parent

                            text: "CONFIRM"

                            color: Theme.Theme.accent

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 8
                            font.bold: true
                        }

                        MouseArea {
                            id: confirmMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: root.executePendingAction()
                        }
                    }
                }
            }
        }
    }
}
