import Quickshell
import Quickshell.Io
import QtQuick

import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem

    property bool connected: false
    property string connectionType: ""
    property string connectionName: ""

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 300
    height: 145

    visible: false
    color: "transparent"
    
    // El popup no necesita capturar el teclado
    grabFocus: true

    Process {
        id: networkProbe

        command: [
            "nmcli",
            "-t",
            "-f",
            "TYPE,STATE,CONNECTION",
            "device"
        ]

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                var lines = text.trim().split(/\r?\n/)

                root.connected = false
                root.connectionType = ""
                root.connectionName = ""

                for (var i = 0; i < lines.length; ++i) {
                    var p = lines[i].split(":")

                    if (
                        p.length >= 3 &&
                        p[1] === "connected"
                    ) {
                        root.connected = true
                        root.connectionType = p[0]
                        root.connectionName = p[2]
                        break
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        networkProbe.running = true
    }

    Timer {
        interval: 5000
        running: root.visible
        repeat: true

        onTriggered: {
            if (!networkProbe.running)
                networkProbe.running = true
        }
    }

    Rectangle {
        anchors.fill: parent

        color: Theme.Theme.surface
        border.width: 1
        border.color: Theme.Theme.outline
        radius: 0

        Column {
            anchors.fill: parent
            anchors.margins: 18

            spacing: 12

            Text {
                text: "NETWORK"
                color: Theme.Theme.text

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }

            Row {
                spacing: 12

                Text {
                    text: root.connected
                        ? (
                            root.connectionType === "wifi"
                                ? "󰖩"
                                : "󰈀"
                          )
                        : "󰖪"

                    color: root.connected
                        ? Theme.Theme.accent
                        : Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 24
                }

                Column {
                    spacing: 3

                    Text {
                        text: root.connected
                            ? root.connectionName
                            : "Disconnected"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        text: root.connected
                            ? root.connectionType.toUpperCase()
                            : "NO CONNECTION"

                        color: Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 30

                color: editorMouse.containsMouse
                    ? Theme.Theme.accentSoft
                    : "transparent"

                Text {
                    anchors.centerIn: parent

                    text: "󰖩  Network settings"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 11
                }

                MouseArea {
                    id: editorMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        // Cerramos el popup antes de abrir la TUI
                        root.visible = false

                        Quickshell.execDetached([
                            "sh",
                            "-lc",
                            "if command -v nm-connection-editor >/dev/null 2>&1; then exec nm-connection-editor; elif command -v nmtui >/dev/null 2>&1; then exec kitty --title NetworkManager -e nmtui; fi"
                        ])
                    }
                }
            }
        }
    }
}
