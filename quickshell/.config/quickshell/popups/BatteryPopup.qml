import Quickshell
import Quickshell.Io

import QtQuick

import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 320
    height: 190

    visible: false
    grabFocus: true
    color: "transparent"

    property int percentage: 0
    property string status: "Unknown"
    property string batteryPath: ""

    function updateBattery() {
        batteryProbe.running = true
    }

    Process {
        id: batteryProbe

        command: [
            "sh",
            "-c",
            "for b in /sys/class/power_supply/BAT*; do " +
            "[ -f \"$b/capacity\" ] || continue; " +
            "printf '%s|%s\\n' \"$(cat \"$b/capacity\")\" \"$(cat \"$b/status\" 2>/dev/null || echo Unknown)\"; " +
            "exit; " +
            "done"
        ]

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                var value = text.trim()

                if (!value.length) {
                    root.percentage = -1
                    root.status = "No battery detected"
                    return
                }

                var parts = value.split("|")

                if (parts.length >= 2) {
                    root.percentage = parseInt(parts[0])
                    root.status = parts[1]
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true

        onTriggered: root.updateBattery()
    }

    Component.onCompleted: root.updateBattery()

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
            0.35
        )

        Text {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 18
                leftMargin: 20
                rightMargin: 20
            }

            text: "󰁹  Battery"

            color: Theme.Theme.accent

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 17
            font.weight: Font.Bold
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: 20
                top: parent.top
                topMargin: 58
            }

            text: root.percentage >= 0
                ? root.percentage + "%"
                : "--"

            color: Theme.Theme.text

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 32
            font.weight: Font.Bold
        }

        Text {
            anchors {
                left: parent.left
                leftMargin: 20
                bottom: parent.bottom
                bottomMargin: 22
            }

            text: root.status

            color: Theme.Theme.textMuted

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 13
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 20
                rightMargin: 20
                bottomMargin: 12
            }

            height: 4

            color: Qt.rgba(
                Theme.Theme.outline.r,
                Theme.Theme.outline.g,
                Theme.Theme.outline.b,
                0.25
            )

            Rectangle {
                width: root.percentage > 0
                    ? parent.width * Math.min(root.percentage, 100) / 100
                    : 0

                height: parent.height

                color: Theme.Theme.accent
            }
        }
    }
}
