import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem

    property string clipboardText: ""
    property bool loading: false

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 440
    height: 500

    visible: false
    color: "transparent"
    grabFocus: true     

    function refresh() {
        if (clipboardProcess.running)
            return

        loading = true
        clipboardProcess.running = true
    }

    function copyEntry(entry) {
        if (!entry || entry.trim().length === 0)
            return

        var encoded = Qt.btoa(
            unescape(encodeURIComponent(entry))
        )

        root.visible = false

        Quickshell.execDetached([
            "sh",
            "-lc",
            "printf '%s' '" + encoded +
            "' | base64 -d | cliphist decode | wl-copy"
        ])
    }

    Process {
        id: clipboardProcess

        command: [
            "sh",
            "-lc",
            "cliphist list"
        ]

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                root.clipboardText = text
                root.loading = false
            }
        }
    }

    onVisibleChanged: {
        if (visible)
            refresh()
    }

    Rectangle {
        anchors.fill: parent

        color: Qt.rgba(
            Theme.Theme.surface.r,
            Theme.Theme.surface.g,
            Theme.Theme.surface.b,
            0.985
        )

        border.width: 1

        border.color: Qt.rgba(
            Theme.Theme.outline.r,
            Theme.Theme.outline.g,
            Theme.Theme.outline.b,
            0.60
        )

        // =====================================================
        // HEADER
        // =====================================================

        Rectangle {
            id: header

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: 52

            color: Qt.rgba(
                Theme.Theme.background.r,
                Theme.Theme.background.g,
                Theme.Theme.background.b,
                0.45
            )

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                text: "󰅍"

                color: Theme.Theme.accent

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 19
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 46
                anchors.verticalCenter: parent.verticalCenter

                text: "CLIPBOARD"

                color: Theme.Theme.text

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter

                text: "󰑐"

                color: refreshMouse.containsMouse
                    ? Theme.Theme.accent
                    : Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 16

                MouseArea {
                    id: refreshMouse

                    anchors.fill: parent

                    anchors.margins: -8

                    hoverEnabled: true

                    onClicked: {
                        root.refresh()
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: 1

                color: Qt.rgba(
                    Theme.Theme.outline.r,
                    Theme.Theme.outline.g,
                    Theme.Theme.outline.b,
                    0.25
                )
            }
        }

        // =====================================================
        // HISTORY
        // =====================================================

        Flickable {
            id: historyFlick

            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top

            anchors.margins: 8

            clip: true

            contentWidth: width
            contentHeight: historyColumn.implicitHeight

            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: historyColumn

                width: historyFlick.width

                spacing: 3

                Repeater {
                    model: root.clipboardText.length > 0
                        ? root.clipboardText.split(/\r?\n/)
                        : []

                    delegate: Rectangle {
                        required property string modelData

                        width: historyColumn.width
                        height: modelData.trim().length > 0
                            ? 58
                            : 0

                        visible: modelData.trim().length > 0

                        color: entryMouse.containsMouse
                            ? Qt.rgba(
                                Theme.Theme.accent.r,
                                Theme.Theme.accent.g,
                                Theme.Theme.accent.b,
                                0.12
                            )
                            : "transparent"

                        border.width: entryMouse.containsMouse
                            ? 1
                            : 0

                        border.color: Qt.rgba(
                            Theme.Theme.accent.r,
                            Theme.Theme.accent.g,
                            Theme.Theme.accent.b,
                            0.35
                        )

                        // Icono
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter

                            text: "󰇚"

                            color: entryMouse.containsMouse
                                ? Theme.Theme.accent
                                : Theme.Theme.textMuted

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 16
                        }

                        // Contenido
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 38
                            anchors.right: parent.right
                            anchors.rightMargin: 10

                            anchors.verticalCenter: parent.verticalCenter

                            text: modelData

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 11

                            elide: Text.ElideRight

                            maximumLineCount: 2

                            wrapMode: Text.Wrap
                        }

                        MouseArea {
                            id: entryMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked: {
                                root.copyEntry(modelData)
                            }
                        }
                    }
                }
            }

            // Scroll indicator
            Rectangle {
                visible: historyFlick.contentHeight >
                         historyFlick.height

                width: 3

                height: Math.max(
                    32,
                    historyFlick.height *
                    (
                        historyFlick.height /
                        historyFlick.contentHeight
                    )
                )

                x: historyFlick.width - width - 2

                y: historyFlick.contentHeight <= historyFlick.height
                    ? 0
                    : (
                        historyFlick.contentY /
                        (
                            historyFlick.contentHeight -
                            historyFlick.height
                        )
                    ) *
                    (
                        historyFlick.height - height
                    )

                color: Theme.Theme.accent

                radius: 0
            }

            MouseArea {
                anchors.fill: parent

                acceptedButtons: Qt.NoButton

                onWheel: function(wheel) {
                    historyFlick.contentY = Math.max(
                        0,
                        Math.min(
                            historyFlick.contentHeight -
                            historyFlick.height,
                            historyFlick.contentY -
                            wheel.angleDelta.y
                        )
                    )
                }
            }
        }

        // =====================================================
        // EMPTY / LOADING
        // =====================================================

        Column {
            anchors.centerIn: historyFlick

            spacing: 8

            visible: root.loading ||
                     root.clipboardText.trim().length === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: root.loading
                    ? "󰑐"
                    : "󰅍"

                color: Theme.Theme.accent

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 28
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter

                text: root.loading
                    ? "Loading clipboard..."
                    : "Clipboard vacío"

                color: Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 11
            }
        }

        // =====================================================
        // FOOTER
        // =====================================================

        Rectangle {
            id: footer

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 32

            color: Qt.rgba(
                Theme.Theme.background.r,
                Theme.Theme.background.g,
                Theme.Theme.background.b,
                0.35
            )

            Text {
                anchors.centerIn: parent

                text: "CLICK TO COPY"

                color: Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 9
                font.bold: true
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                height: 1

                color: Qt.rgba(
                    Theme.Theme.outline.r,
                    Theme.Theme.outline.g,
                    Theme.Theme.outline.b,
                    0.20
                )
            }
        }
    }
}
