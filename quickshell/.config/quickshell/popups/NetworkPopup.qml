import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 340
    height: 220

    visible: false
    grabFocus: true
    color: "transparent"

    property bool connected: false
    property string connectionType: ""
    property string connectionName: ""
    property string connectionState: "Disconnected"

    function refresh() {
        if (!networkProbe.running)
            networkProbe.running = true
    }

    Process {
        id: networkProbe

        command: [
            "sh",
            "-lc",
            "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device 2>/dev/null"
        ]

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                var lines = text.trim().split(/\r?\n/)

                root.connected = false
                root.connectionType = ""
                root.connectionName = ""
                root.connectionState = "Disconnected"

                for (var i = 0; i < lines.length; ++i) {
                    var p = lines[i].split(":")

                    if (p.length < 4)
                        continue

                    if (p[2] !== "connected")
                        continue

                    root.connected = true
                    root.connectionType = p[1]
                    root.connectionName = p[3]
                    root.connectionState = "Connected"

                    break
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: root.visible
        repeat: true

        onTriggered: {
            root.refresh()
        }
    }

    Component.onCompleted: {
        root.refresh()
    }

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

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // HEADER
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44

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

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: root.connected
                            ? (root.connectionType === "wifi"
                               ? "󰖩"
                               : "󰈀")
                            : "󰖪"

                        color: root.connected
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 20
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true

                            text: "NETWORK"

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true

                            text: root.connectionState

                            color: root.connected
                                ? Theme.Theme.accent
                                : Theme.Theme.textMuted

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        width: 7
                        height: 7

                        color: root.connected
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted
                    }
                }
            }

            // CONNECTION INFO
            Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 62

    color: Qt.rgba(
        Theme.Theme.background.r,
        Theme.Theme.background.g,
        Theme.Theme.background.b,
        0.75
    )

    border.width: 1

    border.color: Qt.rgba(
        Theme.Theme.outline.r,
        Theme.Theme.outline.g,
        Theme.Theme.outline.b,
        0.35
    )

    Column {
        anchors.fill: parent

        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 8

        spacing: 3

        Text {
            width: parent.width

            text: root.connected
                ? root.connectionName
                : "No active connection"

            color: Theme.Theme.text

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 12
            font.bold: true

            elide: Text.ElideRight
        }

        Text {
            width: parent.width

            text: root.connected
                ? root.connectionType.toUpperCase()
                : "DISCONNECTED"

            color: Theme.Theme.textMuted

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 9
        }
    }
}


            // SETTINGS BUTTON
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38

                color: settingsMouse.containsMouse
                    ? Qt.rgba(
                        Theme.Theme.accent.r,
                        Theme.Theme.accent.g,
                        Theme.Theme.accent.b,
                        0.16
                    )
                    : "transparent"

                border.width: 1

                border.color: settingsMouse.containsMouse
                    ? Qt.rgba(
                        Theme.Theme.accent.r,
                        Theme.Theme.accent.g,
                        Theme.Theme.accent.b,
                        0.35
                    )
                    : "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "󰒓"

                        color: settingsMouse.containsMouse
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 16
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "Network settings"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: settingsMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        root.visible = false

                        Quickshell.execDetached([
                            "kitty",
                            "--title",
                            "NetworkManager",
                            "--override",
                            "initial_window_width=1100",
                            "--override",
                            "initial_window_height=700",
                            "-e",
                            "nmtui"
                        ])
                    }
                }
            }

            // REFRESH
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 24

                color: refreshMouse.containsMouse
                    ? Qt.rgba(
                        Theme.Theme.text.r,
                        Theme.Theme.text.g,
                        Theme.Theme.text.b,
                        0.05
                    )
                    : "transparent"

                Text {
                    anchors.centerIn: parent

                    text: "󰑐  Refresh"

                    color: refreshMouse.containsMouse
                        ? Theme.Theme.accent
                        : Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                }

                MouseArea {
                    id: refreshMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        root.refresh()
                    }
                }
            }
        }
    }
}
