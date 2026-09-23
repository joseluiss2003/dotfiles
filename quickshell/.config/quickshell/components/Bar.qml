import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

import QtQuick
import QtQuick.Effects

import "../generated" as Theme
import "../popups" as Popups


PanelWindow {
    id: root

    required property var barScreen

    screen: barScreen

    anchors {
        top: true
        left: true
        right: true
    }

    // Compact floating bar.
    // The actual frame is 36px high with a tiny outer margin.
    implicitHeight: 46
    exclusiveZone: 42
    color: "transparent"

    property date now: new Date()

    property string focusedApp: "Desktop"
    property string focusedTitle: ""

    property bool networkConnected: false
    property string networkType: ""

    property int batteryPercent: -1
    property string batteryStatus: ""

    // Cover for the currently playing track.
    property string mediaArtUrl: ""
    property string mediaArtFile: ""
    property bool mediaArtLocalReady: false
    property int mediaArtVersion: 0

    property var player: {
        var players = Mpris.players.values

        for (var i = 0; i < players.length; ++i) {
            if (players[i].isPlaying)
                return players[i]
        }

        return players.length > 0 ? players[0] : null
    }

    property var sink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // =========================================================
    // THE SAME PALETTE USED BY THE WORKING POPUPS
    // =========================================================

    function tint(alpha) {
        return Qt.rgba(
            Theme.Theme.accent.r,
            Theme.Theme.accent.g,
            Theme.Theme.accent.b,
            alpha
        )
    }

    function border() {
        return Qt.rgba(
            Theme.Theme.accent.r,
            Theme.Theme.accent.g,
            Theme.Theme.accent.b,
            0.88
        )
    }

    function hover(alpha) {
        return Qt.rgba(
            Theme.Theme.accent.r,
            Theme.Theme.accent.g,
            Theme.Theme.accent.b,
            alpha
        )
    }

    function appIcon(appId) {
        var value = String(appId).toLowerCase()

        if (value.indexOf("firefox") >= 0)
            return "󰈹"
        if (value.indexOf("kitty") >= 0)
            return "󰄛"
        if (value.indexOf("foot") >= 0)
            return "󰆍"
        if (value.indexOf("code") >= 0 || value.indexOf("codium") >= 0)
            return "󰨞"
        if (value.indexOf("steam") >= 0)
            return "󰓓"
        if (value.indexOf("spotify") >= 0)
            return "󰓇"
        if (value.indexOf("discord") >= 0)
            return "󰙯"
        if (value.indexOf("dolphin") >= 0 || value.indexOf("thunar") >= 0)
            return "󰉋"
        if (value.indexOf("nvim") >= 0 || value.indexOf("neovim") >= 0)
            return ""

        return "󰣆"
    }

    function mediaArtValue() {
        if (!root.player)
            return ""

        var url = root.player.trackArtUrl || ""

        if (!url && root.player.metadata) {
            var meta = root.player.metadata
            url = meta["mpris:artUrl"] || meta["xesam:artUrl"] || ""
        }

        return String(url)
    }

    function refreshMediaArt() {
        if (mediaArtDownloader.running)
            mediaArtDownloader.running = false

        root.mediaArtUrl = mediaArtValue()
        root.mediaArtLocalReady = false
        root.mediaArtVersion += 1

        if (!root.mediaArtUrl || !root.player) {
            root.mediaArtFile = ""
            return
        }

        var id = String(root.player.uniqueId)
        if (!id.length)
            id = "current"

        root.mediaArtFile = Quickshell.cachePath("media-cover-" + id + ".img")

        mediaArtDownloader.command = [
            "curl",
            "-L",
            "--fail",
            "--silent",
            "--show-error",
            "--max-time",
            "12",
            "--output",
            root.mediaArtFile,
            root.mediaArtUrl
        ]

        mediaArtDownloader.running = true
    }

    Connections {
        target: root.player

        function onPostTrackChanged() {
            mediaArtDelay.restart()
        }

        function onTrackArtUrlChanged() {
            mediaArtDelay.restart()
        }
    }

    Timer {
        id: mediaArtDelay

        interval: 600
        repeat: false

        onTriggered: root.refreshMediaArt()
    }

    Process {
        id: mediaArtDownloader

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && root.mediaArtFile.length)
                root.mediaArtLocalReady = true
        }
    }

    function appLabel(appId) {
        var value = String(appId)
        var lower = value.toLowerCase()

        if (lower.indexOf("firefox") >= 0)
            return "Firefox"
        if (lower.indexOf("kitty") >= 0)
            return "kitty"
        if (lower.indexOf("foot") >= 0)
            return "foot"
        if (lower.indexOf("steam") >= 0)
            return "Steam"
        if (lower.indexOf("spotify") >= 0)
            return "Spotify"
        if (lower.indexOf("discord") >= 0)
            return "Discord"
        if (lower.indexOf("dolphin") >= 0)
            return "Dolphin"
        if (lower.indexOf("thunar") >= 0)
            return "Thunar"

        return value.length ? value : "Desktop"
    }

    function closePopups() {
        powerPopup.visible = false
        mediaPopup.visible = false
        networkPopup.visible = false
        audioPopup.visible = false
        batteryPopup.visible = false
        calendarPopup.visible = false
    }

    function togglePopup(popup) {
        var wasVisible = popup.visible

        closePopups()

        popup.visible = !wasVisible
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            root.now = new Date()

            if (!focusedProbe.running)
                focusedProbe.running = true
        }
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

    Timer {
        interval: 30000
        running: true
        repeat: true

        onTriggered: {
            if (!batteryProbe.running)
                batteryProbe.running = true
        }
    }

    Process {
        id: focusedProbe

        command: [
            "sh",
            "-lc",
            "swaymsg -t get_tree 2>/dev/null | jq -r '.. | objects | select(.focused? == true) | [(.app_id // .window_properties.class // \"Desktop\"), (.name // \"\")] | @tsv' | head -n1"
        ]

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                var value = text.trim()

                if (!value.length) {
                    root.focusedApp = "Desktop"
                    root.focusedTitle = ""
                    return
                }

                var fields = value.split("\t")

                root.focusedApp =
                    fields.length > 0 && fields[0].length
                    ? fields[0]
                    : "Desktop"

                root.focusedTitle =
                    fields.length > 1
                    ? fields.slice(1).join(" ")
                    : ""
            }
        }
    }

    Process {
        id: networkProbe

        command: [
            "sh",
            "-lc",
            "nmcli -t -f TYPE,STATE device 2>/dev/null"
        ]

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                var lines = text.trim().split(/\r?\n/)

                root.networkConnected = false
                root.networkType = ""

                for (var i = 0; i < lines.length; ++i) {
                    var fields = lines[i].split(":")

                    if (
                        fields.length >= 2 &&
                        fields[1] === "connected"
                    ) {
                        root.networkConnected = true
                        root.networkType = fields[0]
                        break
                    }
                }
            }
        }
    }

    Process {
        id: batteryProbe

        command: [
            "sh",
            "-lc",
            "b=$(find /sys/class/power_supply -maxdepth 2 -name capacity 2>/dev/null | head -n1); if [ -r \"$b\" ]; then s=${b%/capacity}/status; printf '%s\\t%s' \"$(cat \"$b\")\" \"$(cat \"$s\" 2>/dev/null)\"; else printf '%s\\t%s' '-1' ''; fi"
        ]

        stdout: StdioCollector {
            waitForEnd: true

            onStreamFinished: {
                var fields = text.trim().split("\t")
                var value = parseInt(fields[0])

                root.batteryPercent = isNaN(value) ? -1 : value
                root.batteryStatus = fields.length > 1 ? fields[1] : ""
            }
        }
    }

    Component.onCompleted: {
        focusedProbe.running = true
        networkProbe.running = true
        batteryProbe.running = true
        root.refreshMediaArt()
    }

    // =========================================================
    // FLOATING BAR
    // =========================================================

    Rectangle {
        id: frame

        x: 3
        y: 4

        width: parent.width - 6
        height: 36

        // Same base color as the working popups.
        color: Qt.rgba(
            Theme.Theme.background.r,
            Theme.Theme.background.g,
            Theme.Theme.background.b,
            0.92
        )

        border.width: 2
        border.color: root.border()
    }

    // A subtle accent wash, clipped by the square frame.
    Rectangle {
        x: frame.x
        y: frame.y

        width: frame.width
        height: frame.height

        color: root.tint(0.045)
    }

    // =========================================================
    // LEFT: ARCH | FOCUS | MEDIA
    // =========================================================

    Row {
        id: leftModules

        anchors.left: frame.left
        anchors.verticalCenter: frame.verticalCenter

        height: frame.height
        spacing: 0

        Rectangle {
            id: archButton

            width: 38
            height: frame.height

            color: archMouse.containsMouse
                ? root.hover(0.11)
                : "transparent"

            Text {
                anchors.centerIn: parent

                text: ""

                color: Theme.Theme.accent

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 19
            }

            MouseArea {
                id: archMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked: root.togglePopup(powerPopup)
            }
        }

        Rectangle {
            width: 2
            height: frame.height

            color: root.border()
        }

        Rectangle {
            id: focusModule

            width: 188
            height: frame.height

            color: focusMouse.containsMouse
                ? root.hover(0.055)
                : "transparent"

            Row {
                anchors.fill: parent

                anchors.leftMargin: 8
                anchors.rightMargin: 8

                spacing: 7

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.appIcon(root.focusedApp)

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 15
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    width: 157
                    spacing: 0

                    Text {
                        width: parent.width

                        text: root.appLabel(root.focusedApp)

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true

                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width

                        visible: root.focusedTitle.length > 0

                        text: root.focusedTitle

                        color: Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 8

                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                id: focusMouse

                anchors.fill: parent
                hoverEnabled: true
            }
        }

        Rectangle {
            width: 2
            height: frame.height

            color: root.border()
        }

        Rectangle {
            id: mediaModule

            visible: root.player !== null

            width: visible ? 238 : 0
            height: frame.height

            color: mediaMouse.containsMouse
                ? root.hover(0.055)
                : "transparent"

            Row {
                anchors.fill: parent

                anchors.leftMargin: 6
                anchors.rightMargin: 6

                spacing: 5

                // Album / track cover
                Item {
                    id: mediaArt

                    width: 22
                    height: 22

                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent

                        color: root.tint(0.08)
                        border.width: 1
                        border.color: root.tint(0.42)

                        Image {
                            id: mediaArtImage

                            anchors.fill: parent

                            // First try the MPRIS URL, then use the local
                            // cached copy. This makes Spotify artwork reliable
                            // even when its artwork URL is remote.
                            source: root.mediaArtLocalReady
                                ? "file://" + root.mediaArtFile + "?v=" + root.mediaArtVersion
                                : root.mediaArtUrl

                            asynchronous: true
                            cache: false
                            smooth: true
                            fillMode: Image.PreserveAspectCrop

                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent

                            visible: !mediaArtImage.visible
                            text: "󰎈"

                            color: Theme.Theme.accent

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 15
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text:
                        root.player &&
                        root.player.isPlaying
                        ? "󰐊"
                        : "󰏤"

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 14
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    width: 166
                    spacing: 0

                    Text {
                        width: parent.width

                        text:
                            root.player
                            ? (
                                root.player.trackTitle ||
                                root.player.identity ||
                                "Media"
                            )
                            : ""

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true

                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width

                        text:
                            root.player
                            ? (root.player.trackArtist || "")
                            : ""

                        color: Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 8

                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                id: mediaMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked: root.togglePopup(mediaPopup)
            }
        }
    }

    // =========================================================
    // CENTER: SIMPLE WORKSPACE MARKERS
    // =========================================================

    Row {
        id: workspaceRow

        anchors.centerIn: frame

        height: frame.height
        spacing: 7

        Repeater {
            model: I3.workspaces

            delegate: Rectangle {
                required property var modelData

                width: 15
                height: frame.height

                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent

                    width: modelData.focused ? 12 : 9
                    height: modelData.focused ? 12 : 9

                    color:
                        modelData.focused
                        ? Theme.Theme.accent
                        : "transparent"

                    border.width:
                        modelData.focused
                        ? 0
                        : 1

                    border.color:
                        root.border()
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked:
                        modelData.activate()
                }
            }
        }
    }

    // =========================================================
    // RIGHT: TRAY | NETWORK | AUDIO | BATTERY | CLOCK
    // =========================================================

    Row {
        id: rightModules

        anchors.right: frame.right
        anchors.verticalCenter: frame.verticalCenter

        height: frame.height
        spacing: 0

        // Tray is a single clean zone. NO separators between icons.
        Row {
            id: tray

            height: frame.height
            spacing: 1

            Repeater {
                model: SystemTray.items

                delegate: Rectangle {
                    required property var modelData

                    width: 24
                    height: frame.height

                    color:
                        trayMouse.containsMouse
                        ? root.hover(0.09)
                        : "transparent"

                    Image {
                        id: traySource

                        anchors.centerIn: parent

                        width: 18
                        height: 18

                        source: modelData.icon

                        fillMode: Image.PreserveAspectFit
                        smooth: true

                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: traySource

                        source: traySource

                        colorizationColor: Theme.Theme.accent
                        colorization: 1.0
                    }

                    MouseArea {
                        id: trayMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        acceptedButtons:
                            Qt.LeftButton |
                            Qt.RightButton |
                            Qt.MiddleButton

                        onClicked: function(mouse) {
                            if (
                                mouse.button === Qt.RightButton &&
                                modelData.hasMenu
                            ) {
                                modelData.display(
                                    root,
                                    0,
                                    frame.height
                                )
                                return
                            }

                            if (
                                mouse.button === Qt.MiddleButton
                            ) {
                                modelData.secondaryActivate()
                                return
                            }

                            modelData.activate()
                        }
                    }
                }
            }
        }

        Rectangle {
            id: network

            width: 30
            height: frame.height

            color: networkMouse.containsMouse
                ? root.hover(0.08)
                : "transparent"

            Text {
                anchors.centerIn: parent

                text:
                    root.networkConnected
                    ? (
                        root.networkType === "wifi"
                        ? "󰖩"
                        : "󰈀"
                    )
                    : "󰖪"

                color:
                    root.networkConnected
                    ? Theme.Theme.accent
                    : Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 17
            }

            MouseArea {
                id: networkMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked:
                    root.togglePopup(networkPopup)
            }
        }

        Rectangle {
            id: audio

            width: 52
            height: frame.height

            color: audioMouse.containsMouse
                ? root.hover(0.08)
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
                        return "󰖁"

                    return "󰕾 " +
                        Math.round(
                            root.sink.audio.volume * 100
                        ) +
                        "%"
                }

                color:
                    root.sink && root.sink.ready && root.sink.audio
                    ? Theme.Theme.accent
                    : Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 10
                font.bold: true
            }

            MouseArea {
                id: audioMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked:
                    root.togglePopup(audioPopup)

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

        Rectangle {
            id: battery

            width: 56
            height: frame.height

            color: batteryMouse.containsMouse
                ? root.hover(0.08)
                : "transparent"

            Text {
                anchors.centerIn: parent

                text: {
                    if (root.batteryPercent < 0)
                        return "󰂑 —"

                    if (
                        root.batteryStatus === "Charging"
                    )
                        return "󰂄 " +
                            root.batteryPercent +
                            "%"

                    if (root.batteryPercent <= 15)
                        return "󰁺 " +
                            root.batteryPercent +
                            "%"

                    if (root.batteryPercent <= 35)
                        return "󰁼 " +
                            root.batteryPercent +
                            "%"

                    if (root.batteryPercent <= 60)
                        return "󰁾 " +
                            root.batteryPercent +
                            "%"

                    if (root.batteryPercent <= 85)
                        return "󰂀 " +
                            root.batteryPercent +
                            "%"

                    return "󰁹 " +
                        root.batteryPercent +
                        "%"
                }

                color:
                    root.batteryPercent >= 0
                    ? Theme.Theme.accent
                    : Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 10
                font.bold: true
            }

            MouseArea {
                id: batteryMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked:
                    root.togglePopup(batteryPopup)
            }
        }

        Rectangle {
            id: clock

            width: 60
            height: frame.height

            color: clockMouse.containsMouse
                ? root.hover(0.08)
                : "transparent"

            Text {
                anchors.centerIn: parent

                text:
                    Qt.formatDateTime(
                        root.now,
                        "HH:mm"
                    )

                color: Theme.Theme.accent

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }

            MouseArea {
                id: clockMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked:
                    root.togglePopup(calendarPopup)
            }
        }
    }

    // =========================================================
    // POPUPS: ALWAYS OPEN BELOW THE BAR
    // =========================================================

    Popups.PowerPopup {
        id: powerPopup

        anchorItem: archButton
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.ResizeY
        anchor.margins.bottom: 6
    }

    Popups.MediaPopup {
        id: mediaPopup

        anchorItem: mediaModule
        player: root.player
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.ResizeY
        anchor.margins.bottom: 6
    }

    Popups.NetworkPopup {
        id: networkPopup

        anchorItem: network
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.ResizeY
        anchor.margins.bottom: 6
    }

    Popups.AudioPopup {
        id: audioPopup

        anchorItem: audio
        sink: root.sink
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.ResizeY
        anchor.margins.bottom: 6
    }

    Popups.BatteryPopup {
        id: batteryPopup

        anchorItem: battery
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.ResizeY
        anchor.margins.bottom: 6
    }

    Popups.CalendarPopup {
        id: calendarPopup

        anchorItem: clock
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.ResizeY
        anchor.margins.bottom: 6
    }
}
