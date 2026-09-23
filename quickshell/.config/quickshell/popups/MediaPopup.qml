import Quickshell
import Quickshell.Services.Mpris

import QtQuick

import "../generated" as Theme

PopupWindow {
    id: root

    property Item anchorItem
    property var player
    property var activePlayer: player

    property bool playerSelectorOpen: false
    property real seekPreview: -1

    visible: false

    implicitWidth: 360
    implicitHeight: playerSelectorOpen ? 500 : 430

    color: "transparent"

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Top | Edges.Left
    anchor.margins.top: 6

    grabFocus: true

    onVisibleChanged: {
        if (!visible) {
            playerSelectorOpen = false
            seekPreview = -1
        } else if (!activePlayer) {
            activePlayer = player
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

    function outline(alpha) {
        return Qt.rgba(
            Theme.Theme.outline.r,
            Theme.Theme.outline.g,
            Theme.Theme.outline.b,
            alpha
        )
    }

    function formatTime(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            return "0:00"

        var total = Math.floor(seconds)
        var minutes = Math.floor(total / 60)
        var secs = total % 60

        return minutes + ":" + (secs < 10 ? "0" : "") + secs
    }

    function currentPosition() {
        if (!activePlayer)
            return 0

        if (seekPreview >= 0)
            return seekPreview

        return Math.max(0, activePlayer.position)
    }

    function progress() {
        if (!activePlayer || !activePlayer.lengthSupported)
            return 0

        if (activePlayer.length <= 0)
            return 0

        return Math.max(
            0,
            Math.min(
                1,
                currentPosition() / activePlayer.length
            )
        )
    }

    function seekTo(x) {
        if (
            !activePlayer ||
            !activePlayer.canSeek ||
            !activePlayer.positionSupported ||
            !activePlayer.lengthSupported ||
            activePlayer.length <= 0
        )
            return

        var fraction = Math.max(
            0,
            Math.min(
                1,
                x / seekArea.width
            )
        )

        var position = fraction * activePlayer.length

        seekPreview = position
        activePlayer.position = position
    }

    function cycleLoop() {
        if (
            !activePlayer ||
            !activePlayer.canControl ||
            !activePlayer.loopSupported
        )
            return

        // MprisLoopState:
        // None     = 0
        // Track    = 1
        // Playlist = 2

        if (activePlayer.loopState === 0)
            activePlayer.loopState = 2
        else if (activePlayer.loopState === 2)
            activePlayer.loopState = 1
        else
            activePlayer.loopState = 0
    }

    function loopLabel() {
        if (!activePlayer || !activePlayer.loopSupported)
            return "󰕬"

        if (activePlayer.loopState === 1)
            return "󰑘"

        if (activePlayer.loopState === 2)
            return "󰑖"

        return "󰕬"
    }

    function loopActive() {
        return activePlayer &&
               activePlayer.loopSupported &&
               activePlayer.loopState !== 0
    }

    function selectPlayer(selected) {
        activePlayer = selected
        playerSelectorOpen = false
        seekPreview = -1
    }

    Timer {
        interval: 400
        running: root.visible &&
                 root.activePlayer !== null &&
                 root.activePlayer.isPlaying
        repeat: true

        onTriggered: {
            if (root.activePlayer)
                root.activePlayer.positionChanged()

            root.seekPreview = -1
        }
    }

    Connections {
        target: root.activePlayer

        function onTrackChanged() {
            root.seekPreview = -1
        }

        function onPostTrackChanged() {
            root.seekPreview = -1
        }

        function onPlaybackStateChanged() {
            root.seekPreview = -1
        }
    }

    Rectangle {
        anchors.fill: parent

        color: Theme.Theme.background

        border.width: 2
        border.color: Theme.Theme.accent
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // ----------------------------------------------------
        // HEADER / PLAYER SELECTOR
        // ----------------------------------------------------

        Item {
            width: parent.width
            height: 28

            Rectangle {
                anchors.fill: parent

                color: playerSelectorMouse.containsMouse
                    ? accent(0.12)
                    : "transparent"

                border.width: 1
                border.color: playerSelectorOpen
                    ? Theme.Theme.accent
                    : outline(0.35)
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 9
                anchors.rightMargin: 9
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: "󰎆"

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 14
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 34
                    spacing: 1

                    Text {
                        width: parent.width

                        text: root.activePlayer
                            ? root.activePlayer.identity
                            : "NO PLAYER"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 8
                        font.bold: true

                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width

                        text: root.activePlayer
                            ? (
                                root.activePlayer.isPlaying
                                    ? "PLAYING"
                                    : "PAUSED"
                              )
                            : "NO MEDIA"

                        color: Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 7
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.playerSelectorOpen
                        ? "󰅃"
                        : "󰅀"

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 13
                }
            }

            MouseArea {
                id: playerSelectorMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    if (Mpris.players.values.length > 1)
                        root.playerSelectorOpen = !root.playerSelectorOpen
                }
            }
        }

        // ----------------------------------------------------
        // PLAYER LIST
        // ----------------------------------------------------

        Rectangle {
            width: parent.width
            height: root.playerSelectorOpen ? 60 : 0

            visible: root.playerSelectorOpen

            color: accent(0.05)

            border.width: 1
            border.color: outline(0.30)

            clip: true

            ListView {
                anchors.fill: parent

                anchors.margins: 4

                model: Mpris.players

                spacing: 2

                delegate: Item {
                    required property var modelData

                    width: ListView.view.width
                    height: 24

                    Rectangle {
                        anchors.fill: parent

                        color: playerMouse.containsMouse
                            ? accent(0.12)
                            : (
                                root.activePlayer === modelData
                                    ? accent(0.08)
                                    : "transparent"
                              )

                        border.width: root.activePlayer === modelData ? 1 : 0
                        border.color: Theme.Theme.accent
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 7
                        anchors.rightMargin: 7
                        spacing: 7

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: modelData.isPlaying
                                ? "󰐊"
                                : "󰏤"

                            color: Theme.Theme.accent

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 10
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            width: parent.width - 22

                            text: modelData.identity

                            color: Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 8

                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: playerMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: root.selectPlayer(modelData)
                    }
                }
            }
        }

        // ----------------------------------------------------
        // ALBUM ART + INFO
        // ----------------------------------------------------

        Row {
            width: parent.width
            height: 126

            spacing: 12

            Rectangle {
                width: 126
                height: 126

                color: accent(0.05)

                border.width: 2
                border.color: Theme.Theme.accent

                Image {
                    anchors.fill: parent
                    anchors.margins: 2

                    source: root.activePlayer
                        ? root.activePlayer.trackArtUrl
                        : ""

                    asynchronous: true
                    cache: true

                    fillMode: Image.PreserveAspectCrop

                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent

                    text: "󰝚"

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 34

                    visible: root.activePlayer === null ||
                             root.activePlayer.trackArtUrl === ""
                }
            }

            Column {
                width: parent.width - 138
                height: parent.height

                spacing: 6

                Item {
                    width: parent.width
                    height: 38

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        text: root.activePlayer
                            ? (
                                root.activePlayer.trackTitle ||
                                "Unknown Title"
                              )
                            : "Nothing playing"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true

                        wrapMode: Text.Wrap
                        maximumLineCount: 2

                        elide: Text.ElideRight
                    }
                }

                Text {
                    width: parent.width

                    text: root.activePlayer
                        ? (
                            root.activePlayer.trackArtist ||
                            "Unknown Artist"
                          )
                        : "—"

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true

                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width

                    text: root.activePlayer
                        ? (
                            root.activePlayer.trackAlbum ||
                            "Unknown Album"
                          )
                        : "—"

                    color: Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 8

                    elide: Text.ElideRight
                }

                Item {
                    width: parent.width
                    height: 1
                }

                Text {
                    width: parent.width

                    text: root.activePlayer
                        ? root.activePlayer.identity
                        : "No media player"

                    color: Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 7

                    elide: Text.ElideRight
                }
            }
        }

        // ----------------------------------------------------
        // PROGRESS BAR
        // ----------------------------------------------------

        Item {
            id: seekArea

            width: parent.width
            height: 28

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                height: 4

                color: accent(0.15)
            }

            Rectangle {
                width: parent.width * root.progress()
                height: 4

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.Theme.accent
            }

            Rectangle {
                width: 10
                height: 10

                radius: 5

                x: Math.max(
                    0,
                    Math.min(
                        parent.width - width,
                        parent.width * root.progress() - width / 2
                    )
                )

                anchors.verticalCenter: parent.verticalCenter

                color: Theme.Theme.accent

                visible: root.activePlayer !== null &&
                         root.activePlayer.canSeek
            }

            MouseArea {
                anchors.fill: parent

                enabled: root.activePlayer !== null &&
                         root.activePlayer.canSeek &&
                         root.activePlayer.positionSupported &&
                         root.activePlayer.lengthSupported

                onPressed: function(mouse) {
                    root.seekTo(mouse.x)
                }

                onPositionChanged: function(mouse) {
                    if (pressed)
                        root.seekTo(mouse.x)
                }

                onReleased: function(mouse) {
                    root.seekTo(mouse.x)
                }
            }
        }

        Row {
            width: parent.width

            Text {
                text: root.formatTime(root.currentPosition())

                color: Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 8
                font.bold: true
            }

            Item {
                width: parent.width - 75
                height: 1
            }

            Text {
                text: root.activePlayer &&
                      root.activePlayer.lengthSupported
                    ? root.formatTime(root.activePlayer.length)
                    : "--:--"

                color: Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 8
                font.bold: true
            }
        }

        // ----------------------------------------------------
        // MAIN CONTROLS
        // ----------------------------------------------------

        Row {
            width: parent.width
            height: 48

            spacing: 6

            Item {
                width: 36
                height: 36
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent

                    color: previousMouse.containsMouse
                        ? accent(0.12)
                        : "transparent"

                    border.width: 1
                    border.color: previousMouse.containsMouse
                        ? Theme.Theme.accent
                        : outline(0.25)
                }

                Text {
                    anchors.centerIn: parent

                    text: "󰒮"

                    color: root.activePlayer &&
                           root.activePlayer.canGoPrevious
                        ? Theme.Theme.text
                        : Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 17
                }

                MouseArea {
                    id: previousMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    enabled: root.activePlayer !== null &&
                             root.activePlayer.canGoPrevious

                    onClicked: root.activePlayer.previous()
                }
            }

            Item {
                width: 48
                height: 48
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent

                    color: playMouse.containsMouse
                        ? accent(0.22)
                        : accent(0.10)

                    border.width: 2
                    border.color: Theme.Theme.accent
                }

                Text {
                    anchors.centerIn: parent

                    text: root.activePlayer &&
                          root.activePlayer.isPlaying
                        ? "󰏤"
                        : "󰐊"

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 21
                }

                MouseArea {
                    id: playMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    enabled: root.activePlayer !== null &&
                             root.activePlayer.canTogglePlaying

                    onClicked: root.activePlayer.togglePlaying()
                }
            }

            Item {
                width: 36
                height: 36
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent

                    color: nextMouse.containsMouse
                        ? accent(0.12)
                        : "transparent"

                    border.width: 1
                    border.color: nextMouse.containsMouse
                        ? Theme.Theme.accent
                        : outline(0.25)
                }

                Text {
                    anchors.centerIn: parent

                    text: "󰒭"

                    color: root.activePlayer &&
                           root.activePlayer.canGoNext
                        ? Theme.Theme.text
                        : Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 17
                }

                MouseArea {
                    id: nextMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    enabled: root.activePlayer !== null &&
                             root.activePlayer.canGoNext

                    onClicked: root.activePlayer.next()
                }
            }

            Item {
                width: parent.width - 136
                height: 1
            }
        }

        // ----------------------------------------------------
        // SHUFFLE / REPEAT / PLAYER
        // ----------------------------------------------------

        Row {
            width: parent.width
            height: 32

            spacing: 5

            Item {
                width: 32
                height: 30

                Rectangle {
                    anchors.fill: parent

                    color: shuffleMouse.containsMouse ||
                           (
                               root.activePlayer &&
                               root.activePlayer.shuffleSupported &&
                               root.activePlayer.shuffle
                           )
                        ? accent(0.12)
                        : "transparent"

                    border.width:
                        root.activePlayer &&
                        root.activePlayer.shuffleSupported &&
                        root.activePlayer.shuffle
                            ? 1
                            : 0

                    border.color: Theme.Theme.accent
                }

                Text {
                    anchors.centerIn: parent

                    text: "󰒝"

                    color:
                        root.activePlayer &&
                        root.activePlayer.shuffleSupported
                            ? (
                                root.activePlayer.shuffle
                                    ? Theme.Theme.accent
                                    : Theme.Theme.textMuted
                              )
                            : outline(0.35)

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 14
                }

                MouseArea {
                    id: shuffleMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    enabled: root.activePlayer !== null &&
                             root.activePlayer.canControl &&
                             root.activePlayer.shuffleSupported

                    onClicked: {
                        root.activePlayer.shuffle =
                            !root.activePlayer.shuffle
                    }
                }
            }

            Item {
                width: 32
                height: 30

                Rectangle {
                    anchors.fill: parent

                    color: repeatMouse.containsMouse ||
                           root.loopActive()
                        ? accent(0.12)
                        : "transparent"

                    border.width: root.loopActive()
                        ? 1
                        : 0

                    border.color: Theme.Theme.accent
                }

                Text {
                    anchors.centerIn: parent

                    text: root.loopLabel()

                    color:
                        root.activePlayer &&
                        root.activePlayer.loopSupported
                            ? (
                                root.loopActive()
                                    ? Theme.Theme.accent
                                    : Theme.Theme.textMuted
                              )
                            : outline(0.35)

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 14
                }

                MouseArea {
                    id: repeatMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    enabled: root.activePlayer !== null &&
                             root.activePlayer.canControl &&
                             root.activePlayer.loopSupported

                    onClicked: root.cycleLoop()
                }
            }

            Item {
                width: parent.width - 74
                height: 30

                Rectangle {
                    anchors.fill: parent

                    color: "transparent"

                    border.width: 1
                    border.color: outline(0.28)
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: "󰎆"

                        color: Theme.Theme.accent

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 12
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        width: parent.width - 22

                        text: root.activePlayer
                            ? root.activePlayer.identity
                            : "NO PLAYER"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 7
                        font.bold: true

                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        if (Mpris.players.values.length > 1)
                            root.playerSelectorOpen =
                                !root.playerSelectorOpen
                    }
                }
            }
        }

        // ----------------------------------------------------
        // PLAYER ACTION
        // ----------------------------------------------------

        Item {
            width: parent.width
            height: 28

            Rectangle {
                anchors.fill: parent

                color: raiseMouse.containsMouse
                    ? accent(0.10)
                    : "transparent"

                border.width: 1
                border.color: raiseMouse.containsMouse
                    ? Theme.Theme.accent
                    : outline(0.25)
            }

            Text {
                anchors.centerIn: parent

                text: root.activePlayer
                    ? "󰒅  OPEN " + root.activePlayer.identity
                    : "NO PLAYER"

                color: root.activePlayer &&
                       root.activePlayer.canRaise
                    ? Theme.Theme.text
                    : Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 7
                font.bold: true
            }

            MouseArea {
                id: raiseMouse

                anchors.fill: parent
                hoverEnabled: true

                enabled: root.activePlayer !== null &&
                         root.activePlayer.canRaise

                onClicked: root.activePlayer.raise()
            }
        }
    }
}
