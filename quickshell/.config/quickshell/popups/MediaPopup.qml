import Quickshell
import QtQuick

import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem
    required property var player

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 340
    height: 190

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
            anchors.margins: 16
            spacing: 12

            Row {
                width: parent.width
                height: 82
                spacing: 14

                Rectangle {
                    width: 82
                    height: 82

                    color: Theme.Theme.surfaceAlt

                    Image {
                        anchors.fill: parent

                        source: root.player
                            ? root.player.trackArtUrl
                            : ""

                        fillMode: Image.PreserveAspectCrop
                        smooth: true

                        visible: source !== ""
                    }

                    Text {
                        anchors.centerIn: parent

                        text: "󰎆"

                        color: Theme.Theme.accent

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 30

                        visible: !root.player ||
                                 root.player.trackArtUrl === ""
                    }
                }

                Column {
                    width: parent.width - 96
                    anchors.verticalCenter: parent.verticalCenter

                    spacing: 5

                    Text {
                        width: parent.width

                        text: root.player
                            ? (
                                root.player.trackTitle ||
                                "Unknown title"
                              )
                            : "No media"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 14
                        font.bold: true

                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width

                        text: root.player
                            ? (
                                root.player.trackArtist ||
                                root.player.identity ||
                                ""
                              )
                            : ""

                        color: Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 11

                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width

                        text: root.player
                            ? root.player.identity
                            : ""

                        color: Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10

                        elide: Text.ElideRight
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter

                spacing: 18

                Rectangle {
                    width: 42
                    height: 34

                    color: previousMouse.containsMouse
                        ? Theme.Theme.accentSoft
                        : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "󰒮"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 18
                    }

                    MouseArea {
                        id: previousMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (
                                root.player &&
                                root.player.canGoPrevious
                            )
                                root.player.previous()
                        }
                    }
                }

                Rectangle {
                    width: 50
                    height: 34

                    color: playMouse.containsMouse
                        ? Theme.Theme.accentSoft
                        : Theme.Theme.accent

                    Text {
                        anchors.centerIn: parent

                        text: root.player &&
                              root.player.isPlaying
                            ? "󰏤"
                            : "󰐊"

                        color: root.player &&
                               root.player.isPlaying
                            ? Theme.Theme.text
                            : Theme.Theme.accentText

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 18
                    }

                    MouseArea {
                        id: playMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (
                                root.player &&
                                root.player.canTogglePlaying
                            )
                                root.player.togglePlaying()
                        }
                    }
                }

                Rectangle {
                    width: 42
                    height: 34

                    color: nextMouse.containsMouse
                        ? Theme.Theme.accentSoft
                        : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "󰒭"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 18
                    }

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (
                                root.player &&
                                root.player.canGoNext
                            )
                                root.player.next()
                        }
                    }
                }
            }
        }
    }
}
