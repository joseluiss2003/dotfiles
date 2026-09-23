import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem
    required property var sink

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 330
    height: 226

    visible: false
    grabFocus: true
    color: "transparent"

    property var output: sink
    property var input: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [
            root.output,
            root.input
        ]
    }

    function volume(node) {
        if (!node || !node.ready || !node.audio)
            return 0

        return Math.max(
            0,
            Math.min(1, node.audio.volume)
        )
    }

    function percent(node) {
        return Math.round(volume(node) * 100)
    }

    function deviceName(node, fallback) {
        if (!node)
            return fallback

        if (node.description)
            return node.description

        if (node.nickname)
            return node.nickname

        if (node.name)
            return node.name

        return fallback
    }

    function setOutput(node) {
        if (!node)
            return

        root.output = node
        Pipewire.preferredDefaultAudioSink = node
    }

    function setInput(node) {
        if (!node)
            return

        root.input = node
        Pipewire.preferredDefaultAudioSource = node
    }

    Connections {
        target: Pipewire

        function onDefaultAudioSinkChanged() {
            if (Pipewire.defaultAudioSink)
                root.output = Pipewire.defaultAudioSink
        }

        function onDefaultAudioSourceChanged() {
            if (Pipewire.defaultAudioSource)
                root.input = Pipewire.defaultAudioSource
        }
    }

    Rectangle {
        anchors.fill: parent

        color: Qt.rgba(
            Theme.Theme.background.r,
            Theme.Theme.background.g,
            Theme.Theme.background.b,
            0.98
        )

        border.width: 1

        border.color: Qt.rgba(
            Theme.Theme.outline.r,
            Theme.Theme.outline.g,
            Theme.Theme.outline.b,
            0.7
        )

        ColumnLayout {
            anchors.fill: parent

            anchors.margins: 12

            spacing: 8

            // =========================================================
            // OUTPUT
            // =========================================================

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text:
                        root.output &&
                        root.output.audio &&
                        root.output.audio.muted
                        ? "󰖁"
                        : "󰕾"

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 17
                }

                Text {
                    text: "SALIDA"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.percent(root.output) + "%"

                    color: Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 9
                }

                Text {
                    text:
                        root.output &&
                        root.output.audio &&
                        root.output.audio.muted
                        ? "󰖁"
                        : "󰝟"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 15

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            if (
                                root.output &&
                                root.output.audio
                            ) {
                                root.output.audio.muted =
                                    !root.output.audio.muted
                            }
                        }
                    }
                }
            }

            // Output device

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 22

                Text {
                    anchors.left: parent.left
                    anchors.right: arrow.left

                    anchors.verticalCenter: parent.verticalCenter

                    text: root.deviceName(
                        root.output,
                        "Sin dispositivo de salida"
                    )

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 9

                    elide: Text.ElideRight
                }

                Text {
                    id: arrow

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    text: outputMenu.visible ? "󰅀" : "󰅂"

                    color: Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: {
                        outputMenu.visible =
                            !outputMenu.visible
                    }
                }
            }

            // Output slider

            RowLayout {
                Layout.fillWidth: true

                spacing: 8

                Rectangle {
                    id: outputSlider

                    Layout.fillWidth: true
                    Layout.preferredHeight: 5

                    color: Qt.rgba(
                        Theme.Theme.outline.r,
                        Theme.Theme.outline.g,
                        Theme.Theme.outline.b,
                        0.4
                    )

                    Rectangle {
                        width:
                            outputSlider.width *
                            root.volume(root.output)

                        height: parent.height

                        color: Theme.Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent

                        function updateVolume(x) {
                            if (
                                !root.output ||
                                !root.output.audio
                            )
                                return

                            root.output.audio.volume =
                                Math.max(
                                    0,
                                    Math.min(
                                        1,
                                        x / width
                                    )
                                )
                        }

                        onPressed: function(mouse) {
                            updateVolume(mouse.x)
                        }

                        onPositionChanged: function(mouse) {
                            if (pressed)
                                updateVolume(mouse.x)
                        }
                    }
                }
            }

            // =========================================================
            // SEPARATOR
            // =========================================================

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1

                color: Qt.rgba(
                    Theme.Theme.outline.r,
                    Theme.Theme.outline.g,
                    Theme.Theme.outline.b,
                    0.25
                )
            }

            // =========================================================
            // INPUT
            // =========================================================

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text:
                        root.input &&
                        root.input.audio &&
                        root.input.audio.muted
                        ? "󰍭"
                        : "󰍬"

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 17
                }

                Text {
                    text: "ENTRADA"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.percent(root.input) + "%"

                    color: Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 9
                }

                Text {
                    text:
                        root.input &&
                        root.input.audio &&
                        root.input.audio.muted
                        ? "󰍭"
                        : "󰍬"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 15

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            if (
                                root.input &&
                                root.input.audio
                            ) {
                                root.input.audio.muted =
                                    !root.input.audio.muted
                            }
                        }
                    }
                }
            }

            // Input device

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 22

                Text {
                    anchors.left: parent.left
                    anchors.right: inputArrow.left

                    anchors.verticalCenter: parent.verticalCenter

                    text: root.deviceName(
                        root.input,
                        "Sin dispositivo de entrada"
                    )

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 9

                    elide: Text.ElideRight
                }

                Text {
                    id: inputArrow

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    text: inputMenu.visible ? "󰅀" : "󰅂"

                    color: Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: {
                        inputMenu.visible =
                            !inputMenu.visible
                    }
                }
            }

            // Input slider

            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    id: inputSlider

                    Layout.fillWidth: true
                    Layout.preferredHeight: 5

                    color: Qt.rgba(
                        Theme.Theme.outline.r,
                        Theme.Theme.outline.g,
                        Theme.Theme.outline.b,
                        0.4
                    )

                    Rectangle {
                        width:
                            inputSlider.width *
                            root.volume(root.input)

                        height: parent.height

                        color: Theme.Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent

                        function updateVolume(x) {
                            if (
                                !root.input ||
                                !root.input.audio
                            )
                                return

                            root.input.audio.volume =
                                Math.max(
                                    0,
                                    Math.min(
                                        1,
                                        x / width
                                    )
                                )
                        }

                        onPressed: function(mouse) {
                            updateVolume(mouse.x)
                        }

                        onPositionChanged: function(mouse) {
                            if (pressed)
                                updateVolume(mouse.x)
                        }
                    }
                }
            }
        }
    }

    // ================================================================
    // OUTPUT MENU
    // ================================================================

    PopupWindow {
        id: outputMenu

        anchor.item: root

        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        width: 330
        height: Math.min(
            220,
            Math.max(
                42,
                outputModel.count * 34 + 4
            )
        )

        color: "transparent"

        Rectangle {
            anchors.fill: parent

            color: Qt.rgba(
                Theme.Theme.background.r,
                Theme.Theme.background.g,
                Theme.Theme.background.b,
                0.99
            )

            border.width: 1

            border.color: Qt.rgba(
                Theme.Theme.outline.r,
                Theme.Theme.outline.g,
                Theme.Theme.outline.b,
                0.7
            )

            ListView {
                anchors.fill: parent
                anchors.margins: 2

                clip: true

                model: outputModel

                delegate: Item {
                    required property var modelData

                    width: ListView.view.width
                    height: 34

                    Rectangle {
                        anchors.fill: parent

                        color:
                            root.output === modelData
                            ? Qt.rgba(
                                Theme.Theme.accent.r,
                                Theme.Theme.accent.g,
                                Theme.Theme.accent.b,
                                0.12
                            )
                            : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent

                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        Text {
                            text:
                                root.output === modelData
                                ? "󰄬"
                                : "󰕾"

                            color:
                                root.output === modelData
                                ? Theme.Theme.accent
                                : Theme.Theme.textMuted

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 13
                        }

                        Text {
                            Layout.fillWidth: true

                            text: root.deviceName(
                                modelData,
                                "Salida"
                            )

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 9

                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            root.setOutput(modelData)
                            outputMenu.visible = false
                        }
                    }
                }
            }
        }
    }

    // ================================================================
    // INPUT MENU
    // ================================================================

    PopupWindow {
        id: inputMenu

        anchor.item: root

        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        width: 330
        height: Math.min(
            220,
            Math.max(
                42,
                inputModel.count * 34 + 4
            )
        )

        color: "transparent"

        Rectangle {
            anchors.fill: parent

            color: Qt.rgba(
                Theme.Theme.background.r,
                Theme.Theme.background.g,
                Theme.Theme.background.b,
                0.99
            )

            border.width: 1

            border.color: Qt.rgba(
                Theme.Theme.outline.r,
                Theme.Theme.outline.g,
                Theme.Theme.outline.b,
                0.7
            )

            ListView {
                anchors.fill: parent
                anchors.margins: 2

                clip: true

                model: inputModel

                delegate: Item {
                    required property var modelData

                    width: ListView.view.width
                    height: 34

                    Rectangle {
                        anchors.fill: parent

                        color:
                            root.input === modelData
                            ? Qt.rgba(
                                Theme.Theme.accent.r,
                                Theme.Theme.accent.g,
                                Theme.Theme.accent.b,
                                0.12
                            )
                            : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent

                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        Text {
                            text:
                                root.input === modelData
                                ? "󰄬"
                                : "󰍬"

                            color:
                                root.input === modelData
                                ? Theme.Theme.accent
                                : Theme.Theme.textMuted

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 13
                        }

                        Text {
                            Layout.fillWidth: true

                            text: root.deviceName(
                                modelData,
                                "Entrada"
                            )

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 9

                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            root.setInput(modelData)
                            inputMenu.visible = false
                        }
                    }
                }
            }
        }
    }

    // ================================================================
    // DEVICE MODELS
    // ================================================================

    ScriptModel {
        id: outputModel

        values: {
            if (!Pipewire.ready)
                return []

            return Array.from(Pipewire.nodes).filter(
                node =>
                    node &&
                    node.ready &&
                    node.audio &&
                    node.isSink &&
                    !node.isStream
            )
        }
    }

    ScriptModel {
        id: inputModel

        values: {
            if (!Pipewire.ready)
                return []

            return Array.from(Pipewire.nodes).filter(
                node =>
                    node &&
                    node.ready &&
                    node.audio &&
                    !node.isSink &&
                    !node.isStream
            )
        }
    }
}
