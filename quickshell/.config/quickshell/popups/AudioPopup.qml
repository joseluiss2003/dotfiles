import Quickshell
import QtQuick

import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem
    required property var sink

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 300
    height: 150

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
            anchors.margins: 18
            spacing: 14

            Text {
                text: "AUDIO"

                color: Theme.Theme.text
                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }

            Row {
                width: parent.width
                spacing: 12

                Text {
                    width: 32
                    anchors.verticalCenter: parent.verticalCenter

                    text: {
                        if (!root.sink || !root.sink.audio)
                            return "󰕾"

                        if (root.sink.audio.muted)
                            return "󰝟"

                        return "󰖀"
                    }

                    color: Theme.Theme.accent
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 22
                }

                Rectangle {
                    width: parent.width - 80
                    height: 8
                    anchors.verticalCenter: parent.verticalCenter

                    color: Theme.Theme.surfaceAlt

                    Rectangle {
                        width: parent.width *
                            (
                                root.sink &&
                                root.sink.audio
                                    ? root.sink.audio.volume
                                    : 0
                            )

                        height: parent.height

                        color: Theme.Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: function(mouse) {
                            if (!root.sink || !root.sink.audio)
                                return

                            root.sink.audio.volume =
                                Math.max(
                                    0,
                                    Math.min(
                                        1,
                                        mouse.x / width
                                    )
                                )
                        }
                    }
                }

                Text {
                    width: 36

                    anchors.verticalCenter: parent.verticalCenter

                    horizontalAlignment: Text.AlignRight

                    text: root.sink && root.sink.audio
                        ? Math.round(
                            root.sink.audio.volume * 100
                          ) + "%"
                        : "0%"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12
                }
            }

            Rectangle {
                width: parent.width
                height: 34

                color: muteMouse.containsMouse
                    ? Theme.Theme.accentSoft
                    : "transparent"

                Text {
                    anchors.centerIn: parent

                    text: root.sink &&
                          root.sink.audio &&
                          root.sink.audio.muted
                        ? "󰝟  Unmute"
                        : "󰕾  Mute"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: muteMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        if (
                            root.sink &&
                            root.sink.audio
                        ) {
                            root.sink.audio.muted =
                                !root.sink.audio.muted
                        }
                    }
                }
            }
        }
    }
}
