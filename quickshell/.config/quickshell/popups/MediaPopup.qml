import Quickshell
import QtQuick
import QtQuick.Layouts
import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem
    required property var player

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 360
    height: 245

    visible: false
    grabFocus: true
    color: "transparent"

    property real progress: 0

    Timer {
        interval: 500
        running: root.visible && root.player !== null
        repeat: true

        onTriggered: {
            if (!root.player)
                return

            if (root.player.length > 0)
                root.progress = Math.max(
                    0,
                    Math.min(
                        1,
                        root.player.position / root.player.length
                    )
                )
        }
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
            anchors.margins: 14
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                height: 34

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
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰎈"
                        color: Theme.Theme.accent
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 16
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.player
                            ? (root.player.identity || "MEDIA")
                            : "MEDIA"
                        color: Theme.Theme.text
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.player && root.player.isPlaying
                            ? "PLAYING"
                            : "PAUSED"
                        color: Theme.Theme.textMuted
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 8
                        font.bold: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 104
                    Layout.preferredHeight: 104

                    color: Qt.rgba(
                        Theme.Theme.surfaceVariant.r,
                        Theme.Theme.surfaceVariant.g,
                        Theme.Theme.surfaceVariant.b,
                        0.35
                    )

                    border.width: 1

                    border.color: Qt.rgba(
                        Theme.Theme.outline.r,
                        Theme.Theme.outline.g,
                        Theme.Theme.outline.b,
                        0.40
                    )

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1

                        source: root.player
                            ? root.player.trackArtUrl
                            : ""

                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true

                        visible: source !== ""
                    }

                    Text {
                        anchors.centerIn: parent

                        text: "󰎈"

                        color: Theme.Theme.accent

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 34

                        visible:
                            !root.player ||
                            !root.player.trackArtUrl
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 5

                    Text {
                        Layout.fillWidth: true

                        text: root.player
                            ? (root.player.trackTitle || "Unknown title")
                            : "No media"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 14
                        font.bold: true

                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true

                        text: root.player
                            ? (root.player.trackArtist || "Unknown artist")
                            : ""

                        color: Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10

                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true

                        visible: root.player &&
                                 root.player.trackAlbum !== ""

                        text: root.player
                            ? (root.player.trackAlbum || "")
                            : ""

                        color: Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 9

                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 3

                color: Qt.rgba(
                    Theme.Theme.outline.r,
                    Theme.Theme.outline.g,
                    Theme.Theme.outline.b,
                    0.30
                )

                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height

                    color: Theme.Theme.accent
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                spacing: 4

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 34
                    height: 32

                    color: previousMouse.containsMouse
                        ? Theme.Theme.accentSoft
                        : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰒮"
                        color: Theme.Theme.text
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 19
                    }

                    MouseArea {
                        id: previousMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (
                                root.player &&
                                root.player.canGoPrevious
                            ) {
                                root.player.previous()
                            }
                        }
                    }
                }

                Rectangle {
                    width: 42
                    height: 32

                    color: playMouse.containsMouse
                        ? Theme.Theme.accent
                        : "transparent"

                    border.width: 1
                    border.color: Theme.Theme.accent

                    Text {
                        anchors.centerIn: parent

                        text:
                            root.player &&
                            root.player.isPlaying
                                ? "󰏤"
                                : "󰐊"

                        color:
                            playMouse.containsMouse
                            ? Theme.Theme.onPrimary
                            : Theme.Theme.accent

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 20
                    }

                    MouseArea {
                        id: playMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (
                                root.player &&
                                root.player.canTogglePlaying
                            ) {
                                root.player.togglePlaying()
                            }
                        }
                    }
                }

                Rectangle {
                    width: 34
                    height: 32

                    color: nextMouse.containsMouse
                        ? Theme.Theme.accentSoft
                        : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰒭"
                        color: Theme.Theme.text
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 19
                    }

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (
                                root.player &&
                                root.player.canGoNext
                            ) {
                                root.player.next()
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
