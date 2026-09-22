import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

import QtQuick

import "../generated" as Theme
import "../popups" as Popups
import "." as Components

PanelWindow {
    id: root

    required property var barScreen

    screen: barScreen

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 34
    exclusiveZone: 34
    color: "transparent"

    property var player: {
        var players = Mpris.players.values

        for (var i = 0; i < players.length; ++i) {
            if (players[i].isPlaying)
                return players[i]
        }

        return players.length > 0 ? players[0] : null
    }

    property var sink: Pipewire.defaultAudioSink
    property date currentTime: new Date()

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    function togglePopup(popup) {
        var oldState = popup.visible

        audioPopup.visible = false
        mediaPopup.visible = false
        networkPopup.visible = false
        calendarPopup.visible = false
        powerPopup.visible = false
        clipboardPopup.visible = false
        screenshotPopup.visible = false

        popup.visible = !oldState
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            root.currentTime = new Date()
        }
    }

    Rectangle {
        anchors.fill: parent

        color: Qt.rgba(
            Theme.Theme.background.r,
            Theme.Theme.background.g,
            Theme.Theme.background.b,
            0.82
        )

        border.width: 1

        border.color: Qt.rgba(
            Theme.Theme.outline.r,
            Theme.Theme.outline.g,
            Theme.Theme.outline.b,
            0.22
        )
    }

    // =========================================================
    // LEFT SIDE
    // =========================================================

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        spacing: 1

        // Launcher
        Rectangle {
            width: 30
            height: 28

            color: launcherMouse.containsMouse
                ? Qt.rgba(
                    Theme.Theme.text.r,
                    Theme.Theme.text.g,
                    Theme.Theme.text.b,
                    0.08
                )
                : "transparent"

            Text {
                anchors.centerIn: parent

                text: "󰣇"

                color: Theme.Theme.accent

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 18
            }

            MouseArea {
                id: launcherMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    Quickshell.execDetached([
                        "sh",
                        "-lc",
                        "if command -v fuzzel >/dev/null 2>&1; then fuzzel --show drun; elif command -v wofi >/dev/null 2>&1; then wofi --show drun; fi"
                    ])
                }
            }
        }

        // Workspaces
        Row {
            spacing: 0

            Repeater {
                model: I3.workspaces

                delegate: Rectangle {
                    required property var modelData

                    width: modelData.focused ? 28 : 24
                    height: 28

                    color: modelData.focused
                        ? Qt.rgba(
                            Theme.Theme.accent.r,
                            Theme.Theme.accent.g,
                            Theme.Theme.accent.b,
                            0.18
                        )
                        : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: String(modelData.name)

                        color: modelData.focused
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 13
                        font.weight: modelData.focused
                            ? Font.Bold
                            : Font.Medium
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            modelData.activate()
                        }
                    }
                }
            }
        }

        // Media
        Rectangle {
            id: mediaModule

            visible: root.player !== null

            width: visible ? 170 : 0
            height: 28

            color: mediaMouse.containsMouse
                ? Qt.rgba(
                    Theme.Theme.text.r,
                    Theme.Theme.text.g,
                    Theme.Theme.text.b,
                    0.08
                )
                : "transparent"

            Row {
                anchors.fill: parent

                anchors.leftMargin: 7
                anchors.rightMargin: 7

                spacing: 7

                Text {
                    width: 20

                    anchors.verticalCenter: parent.verticalCenter

                    text: root.player &&
                          root.player.isPlaying
                        ? "󰐊"
                        : "󰏤"

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 16
                }

                Text {
                    width: parent.width - 27

                    anchors.verticalCenter: parent.verticalCenter

                    text: root.player
                        ? (
                            root.player.trackTitle ||
                            root.player.identity ||
                            ""
                        )
                        : ""

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12

                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: mediaMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    root.togglePopup(mediaPopup)
                }
            }
        }
    }

    // =========================================================
    // CLOCK
    // =========================================================

    Rectangle {
        id: clock

        anchors.centerIn: parent

        width: 72
        height: 28

        color: clockMouse.containsMouse
            ? Qt.rgba(
                Theme.Theme.text.r,
                Theme.Theme.text.g,
                Theme.Theme.text.b,
                0.08
            )
            : "transparent"

        Text {
            anchors.centerIn: parent

            text: Qt.formatDateTime(
                root.currentTime,
                "HH:mm"
            )

            color: Theme.Theme.text

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        MouseArea {
            id: clockMouse

            anchors.fill: parent
            hoverEnabled: true

            onClicked: {
                root.togglePopup(calendarPopup)
            }
        }
    }

    // =========================================================
    // RIGHT SIDE
    // =========================================================

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        spacing: 1

        // System tray
        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                width: 28
                height: 28

                color: trayMouse.containsMouse
                    ? Qt.rgba(
                        Theme.Theme.text.r,
                        Theme.Theme.text.g,
                        Theme.Theme.text.b,
                        0.08
                    )
                    : "transparent"

                Image {
                    anchors.centerIn: parent

                    width: 17
                    height: 17

                    source: modelData.icon

                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: trayMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        modelData.activate()
                    }
                }
            }
        }

        // Clipboard
        Components.ClipboardButton {
            id: clipboardButton

            anchors.verticalCenter: parent.verticalCenter


            onClicked: {
                root.togglePopup(clipboardPopup)
            }
        }

        // Screenshot
        Components.ScreenshotButton {
            id: screenshotButton

            anchors.verticalCenter: parent.verticalCenter


            onClicked: {
                root.togglePopup(screenshotPopup)
            }
        }

        // Network
        Rectangle {
            id: network

            width: 30
            height: 28

            property bool connected: false
            property string type: ""

            color: networkMouse.containsMouse
                ? Qt.rgba(
                    Theme.Theme.text.r,
                    Theme.Theme.text.g,
                    Theme.Theme.text.b,
                    0.08
                )
                : "transparent"

            Process {
                id: networkProbe

                command: [
                    "nmcli",
                    "-t",
                    "-f",
                    "TYPE,STATE",
                    "device"
                ]

                stdout: StdioCollector {
                    waitForEnd: true

                    onStreamFinished: {
                        var lines = text.trim().split(/\r?\n/)

                        network.connected = false
                        network.type = ""

                        for (var i = 0; i < lines.length; ++i) {
                            var p = lines[i].split(":")

                            if (
                                p.length >= 2 &&
                                p[1] === "connected"
                            ) {
                                network.connected = true
                                network.type = p[0]
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
                running: true
                repeat: true

                onTriggered: {
                    if (!networkProbe.running)
                        networkProbe.running = true
                }
            }

            Text {
                anchors.centerIn: parent

                text: network.connected
                    ? (
                        network.type === "wifi"
                            ? "󰖩"
                            : "󰈀"
                    )
                    : "󰖪"

                color: network.connected
                    ? Theme.Theme.accent
                    : Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 18
            }

            MouseArea {
                id: networkMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    root.togglePopup(networkPopup)
                }
            }
        }

        // Audio
        Rectangle {
            id: audio

            width: 30
            height: 28

            color: audioMouse.containsMouse
                ? Qt.rgba(
                    Theme.Theme.text.r,
                    Theme.Theme.text.g,
                    Theme.Theme.text.b,
                    0.08
                )
                : "transparent"

            Text {
                anchors.centerIn: parent

                text: {
                    if (
                        !root.sink ||
                        !root.sink.ready ||
                        !root.sink.audio
                    )
                        return "󰕾"

                    if (root.sink.audio.muted)
                        return "󰝟"

                    if (root.sink.audio.volume < 0.35)
                        return "󰕿"

                    return "󰖀"
                }

                color: {
                    if (
                        !root.sink ||
                        !root.sink.ready ||
                        !root.sink.audio
                    )
                        return Theme.Theme.textMuted

                    return root.sink.audio.muted
                        ? Theme.Theme.textMuted
                        : Theme.Theme.accent
                }

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 18
            }

            MouseArea {
                id: audioMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    root.togglePopup(audioPopup)
                }

                onWheel: function(wheel) {
                    if (
                        !root.sink ||
                        !root.sink.ready ||
                        !root.sink.audio
                    )
                        return

                    var step =
                        wheel.angleDelta.y > 0
                        ? 0.03
                        : -0.03

                    root.sink.audio.volume =
                        Math.max(
                            0,
                            Math.min(
                                1,
                                root.sink.audio.volume + step
                            )
                        )
                }
            }
        }

        // Power
        Rectangle {
            id: power

            width: 30
            height: 28

            color: powerMouse.containsMouse
                ? Qt.rgba(
                    Theme.Theme.text.r,
                    Theme.Theme.text.g,
                    Theme.Theme.text.b,
                    0.08
                )
                : "transparent"

            Text {
                anchors.centerIn: parent

                text: "󰐥"

                color: Theme.Theme.accent

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 18
            }

            MouseArea {
                id: powerMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    root.togglePopup(powerPopup)
                }
            }
        }
    }

    // =========================================================
    // POPUPS
    // =========================================================

    Popups.AudioPopup {
        id: audioPopup

        anchorItem: audio
        sink: root.sink
    }

    Popups.MediaPopup {
        id: mediaPopup

        anchorItem: mediaModule
        player: root.player
    }

    Popups.NetworkPopup {
        id: networkPopup

        anchorItem: network
    }

    Popups.CalendarPopup {
        id: calendarPopup

        anchorItem: clock
    }

    Popups.PowerPopup {
        id: powerPopup

        anchorItem: power
    }

    Popups.ClipboardPopup {
        id: clipboardPopup

        anchorItem: clipboardButton
    }

    Popups.ScreenshotPopup {
        id: screenshotPopup

        anchorItem: screenshotButton
    }

}
