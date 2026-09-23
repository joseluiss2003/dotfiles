import Quickshell
import Quickshell.Io

import QtQuick

import "../generated" as Theme

PopupWindow {
    id: root

    property Item anchorItem

    property string managerState: "unknown"
    property string wifiState: "unknown"

    property bool wifiAvailable: false

    property string interfaceName: ""
    property string connectionName: ""
    property string connectionType: ""

    property string ipAddress: ""
    property string gateway: ""
    property string dns: ""

    property string currentSsid: ""
    property string currentSignal: "0"

    property string statusMessage: ""

    property var wifiNetworks: []

    property bool passwordOpen: false
    property string selectedSsid: ""
    property string selectedSecurity: ""
    property string password: ""

    property bool detailsOpen: false

    visible: false

    implicitWidth: 380

    implicitHeight: passwordOpen
        ? 410
        : detailsOpen
            ? 370
            : 320

    color: "transparent"

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Top | Edges.Right
    anchor.margins.top: 6

    grabFocus: true

    onVisibleChanged: {
        if (visible) {
            refresh()
        } else {
            passwordOpen = false
            detailsOpen = false
            password = ""
            selectedSsid = ""
            statusMessage = ""
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

    function parseManagerState(value) {
        var state = value.trim().toLowerCase()

        if (state.indexOf("connected") === 0) {
            managerState = "connected"
            return
        }

        if (state.indexOf("connecting") === 0) {
            managerState = "connecting"
            return
        }

        if (state.indexOf("disconnecting") === 0) {
            managerState = "disconnecting"
            return
        }

        if (state.indexOf("disconnected") === 0) {
            managerState = "disconnected"
            return
        }

        managerState = state
    }

    function parseWifiState(value) {
        var state = value.trim().toLowerCase()

        if (state === "enabled") {
            wifiState = "enabled"
            return
        }

        if (state === "disabled") {
            wifiState = "disabled"
            return
        }

        wifiState = state
    }

    function parseWifiAvailability(text) {
        var lines = text.trim().split("\n")

        wifiAvailable = false

        for (var i = 0; i < lines.length; ++i) {
            if (lines[i].trim().toLowerCase() === "wifi") {
                wifiAvailable = true
                return
            }
        }
    }

    function parseDeviceStatus(text) {
        var lines = text.trim().split("\n")

        interfaceName = ""
        connectionName = ""
        connectionType = ""
        currentSsid = ""
        currentSignal = "0"

        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i].trim()

            if (!line.length)
                continue

            var parts = line.split(":")

            if (parts.length < 3)
                continue

            var device = parts[0]
            var type = parts[1]
            var state = parts[2]

            if (
                state === "connected" &&
                (
                    type === "ethernet" ||
                    type === "wifi"
                )
            ) {
                interfaceName = device
                connectionType = type

                if (parts.length >= 4)
                    connectionName = parts.slice(3).join(":")

                if (type === "wifi")
                    currentSsid = connectionName

                loadIpInformation()
                return
            }
        }
    }

    function parseWifiList(text) {
        var result = []
        var lines = text.trim().split("\n")

        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i].trim()

            if (!line.length)
                continue

            var parts = line.split(":")

            if (parts.length < 3)
                continue

            var ssid = parts[0].trim()
            var signal = parts[1].trim()
            var security = parts.slice(2).join(":").trim()

            if (!ssid.length)
                continue

            var found = false

            for (var j = 0; j < result.length; ++j) {
                if (result[j].ssid === ssid) {
                    found = true

                    if (
                        Number(signal) >
                        Number(result[j].signal)
                    ) {
                        result[j].signal = signal
                        result[j].security = security
                    }

                    break
                }
            }

            if (!found) {
                result.push({
                    ssid: ssid,
                    signal: signal,
                    security: security
                })
            }
        }

        result.sort(function(a, b) {
            return Number(b.signal) - Number(a.signal)
        })

        wifiNetworks = result
    }

    function parseIpInformation(text) {
        var lines = text.trim().split("\n")

        ipAddress = ""
        gateway = ""
        dns = ""

        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i].trim()

            if (!line.length)
                continue

            if (
                !ipAddress &&
                line.indexOf("IP4.ADDRESS") === 0
            ) {
                var addressParts = line.split(":")

                if (addressParts.length >= 2)
                    ipAddress = addressParts.slice(1).join(":")
            }

            if (
                !gateway &&
                line.indexOf("IP4.GATEWAY") === 0
            ) {
                var gatewayParts = line.split(":")

                if (gatewayParts.length >= 2)
                    gateway = gatewayParts.slice(1).join(":")
            }

            if (
                !dns &&
                line.indexOf("IP4.DNS") === 0
            ) {
                var dnsParts = line.split(":")

                if (dnsParts.length >= 2)
                    dns = dnsParts.slice(1).join(":")
            }
        }
    }

    function signalIcon(signal) {
        var value = Number(signal)

        if (value >= 80)
            return "󰤨"

        if (value >= 60)
            return "󰤥"

        if (value >= 40)
            return "󰤢"

        if (value >= 20)
            return "󰤟"

        return "󰤯"
    }

    function networkIcon() {
        if (connectionType === "wifi")
            return signalIcon(currentSignal)

        if (connectionType === "ethernet")
            return "󰈀"

        return "󰖪"
    }

    function managerLabel() {
        if (managerState === "connected")
            return "CONNECTED"

        if (managerState === "connecting")
            return "CONNECTING"

        if (managerState === "disconnecting")
            return "DISCONNECTING"

        if (managerState === "disconnected")
            return "OFFLINE"

        return "UNKNOWN"
    }

    function refresh() {
        managerProcess.exec({
            command: [
                "nmcli",
                "-t",
                "-g",
                "STATE",
                "general"
            ]
        })

        wifiRadioProcess.exec({
            command: [
                "nmcli",
                "-t",
                "-g",
                "enabled",
                "radio",
                "wifi"
            ]
        })

        wifiAvailabilityProcess.exec({
            command: [
                "nmcli",
                "-t",
                "-g",
                "TYPE",
                "device",
                "status"
            ]
        })

        deviceProcess.exec({
            command: [
                "nmcli",
                "-t",
                "-f",
                "DEVICE,TYPE,STATE,CONNECTION",
                "device",
                "status"
            ]
        })

        if (wifiAvailable) {
            wifiProcess.exec({
                command: [
                    "nmcli",
                    "-t",
                    "-f",
                    "SSID,SIGNAL,SECURITY",
                    "device",
                    "wifi",
                    "list"
                ]
            })
        } else {
            wifiNetworks = []
        }
    }

    function loadIpInformation() {
        if (!interfaceName.length)
            return

        ipProcess.exec({
            command: [
                "nmcli",
                "-t",
                "-f",
                "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS",
                "device",
                "show",
                interfaceName
            ]
        })

        connectionProcess.exec({
            command: [
                "nmcli",
                "-t",
                "-g",
                "GENERAL.CONNECTION",
                "device",
                "show",
                interfaceName
            ]
        })
    }

    function scan() {
        if (!wifiAvailable)
            return

        statusMessage = "Scanning…"

        wifiProcess.exec({
            command: [
                "nmcli",
                "-t",
                "-f",
                "SSID,SIGNAL,SECURITY",
                "device",
                "wifi",
                "list",
                "--rescan",
                "yes"
            ]
        })
    }

    function toggleWifi() {
        if (!wifiAvailable)
            return

        var command = wifiState === "enabled"
            ? "off"
            : "on"

        statusMessage =
            command === "on"
                ? "Enabling Wi-Fi…"
                : "Disabling Wi-Fi…"

        wifiToggleProcess.exec({
            command: [
                "nmcli",
                "radio",
                "wifi",
                command
            ]
        })
    }

    function selectNetwork(network) {
        if (!wifiAvailable)
            return

        selectedSsid = network.ssid
        selectedSecurity = network.security

        if (
            network.security === "" ||
            network.security === "--"
        ) {
            connectOpenNetwork()
            return
        }

        password = ""
        passwordOpen = true
    }

    function connectOpenNetwork() {
        statusMessage = "Connecting…"

        connectProcess.exec({
            command: [
                "nmcli",
                "--wait",
                "20",
                "device",
                "wifi",
                "connect",
                selectedSsid
            ]
        })
    }

    function connectPasswordNetwork() {
        if (!password.length)
            return

        statusMessage = "Connecting…"

        connectProcess.exec({
            command: [
                "nmcli",
                "--wait",
                "20",
                "device",
                "wifi",
                "connect",
                selectedSsid,
                "password",
                password
            ]
        })
    }

    Process {
        id: managerProcess

        stdout: StdioCollector {
            onStreamFinished:
                root.parseManagerState(text)
        }
    }

    Process {
        id: wifiRadioProcess

        stdout: StdioCollector {
            onStreamFinished:
                root.parseWifiState(text)
        }
    }

    Process {
        id: wifiAvailabilityProcess

        stdout: StdioCollector {
            onStreamFinished:
                root.parseWifiAvailability(text)
        }
    }

    Process {
        id: deviceProcess

        stdout: StdioCollector {
            onStreamFinished:
                root.parseDeviceStatus(text)
        }

        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.statusMessage =
                    "Network status unavailable"
        }
    }

    Process {
        id: wifiProcess

        stdout: StdioCollector {
            onStreamFinished:
                root.parseWifiList(text)
        }

        onExited: function(exitCode) {
            if (exitCode === 0)
                root.statusMessage = ""
            else
                root.statusMessage = "Wi-Fi scan failed"
        }
    }

    Process {
        id: ipProcess

        stdout: StdioCollector {
            onStreamFinished:
                root.parseIpInformation(text)
        }
    }

    Process {
        id: connectionProcess

        stdout: StdioCollector {
            onStreamFinished:
                root.connectionName = text.trim()
        }
    }

    Process {
        id: wifiToggleProcess

        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.statusMessage = ""
                refreshDelay.restart()
            } else {
                root.statusMessage =
                    "Wi-Fi change failed"
            }
        }
    }

    Process {
        id: connectProcess

        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.statusMessage = "Connected"
                root.passwordOpen = false
                root.password = ""
                refreshDelay.restart()
            } else {
                root.statusMessage =
                    "Connection failed"
            }
        }
    }

    Timer {
        id: refreshTimer

        interval: 5000
        running: root.visible
        repeat: true

        onTriggered:
            root.refresh()
    }

    Timer {
        id: refreshDelay

        interval: 1000
        repeat: false

        onTriggered:
            root.refresh()
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

        spacing: 8

        // ====================================================
        // HEADER
        // ====================================================

        Row {
            width: parent.width
            height: 34

            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter

                text: root.networkIcon()

                color: Theme.Theme.accent

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 19
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                spacing: 2

                Text {
                    text: "NETWORK"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                }

                Text {
                    text: root.managerLabel()

                    color:
                        root.managerState === "connected"
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 8
                    font.bold: true
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1

            color: outline(0.30)
        }

        // ====================================================
        // CURRENT CONNECTION
        // ====================================================

        Text {
            text: "CURRENT CONNECTION"

            color: Theme.Theme.textMuted

            font.family: "JetBrains Mono Nerd Font"
            font.pixelSize: 8
            font.bold: true
        }

        Item {
            width: parent.width
            height: 64

            Rectangle {
                anchors.fill: parent

                color: accent(0.045)

                border.width: 1
                border.color: outline(0.30)
            }

            Row {
                anchors.fill: parent

                anchors.leftMargin: 12
                anchors.rightMargin: 12

                spacing: 11

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.networkIcon()

                    color: Theme.Theme.accent

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 19
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    width: parent.width - 92

                    spacing: 3

                    Text {
                        width: parent.width

                        text:
                            root.connectionName.length
                                ? root.connectionName
                                : (
                                    root.interfaceName.length
                                        ? root.interfaceName
                                        : "NO CONNECTION"
                                  )

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true

                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width

                        text:
                            root.interfaceName.length
                                ? (
                                    root.interfaceName +
                                    "  •  " +
                                    (
                                        root.connectionType === "wifi"
                                            ? "Wi-Fi"
                                            : "Ethernet"
                                    )
                                  )
                                : "Disconnected"

                        color: Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 8

                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width

                        text:
                            root.ipAddress.length
                                ? root.ipAddress
                                : "No IPv4 address"

                        color:
                            root.ipAddress.length
                                ? Theme.Theme.accent
                                : Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 8
                        font.bold: true

                        elide: Text.ElideRight
                    }
                }

                Item {
                    width: 58
                    height: 28

                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent

                        color:
                            infoMouse.containsMouse
                                ? accent(0.12)
                                : "transparent"

                        border.width: 1

                        border.color:
                            detailsOpen
                                ? Theme.Theme.accent
                                : outline(0.30)
                    }

                    Text {
                        anchors.centerIn: parent

                        text:
                            detailsOpen
                                ? "HIDE"
                                : "INFO"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 7
                        font.bold: true
                    }

                    MouseArea {
                        id: infoMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked:
                            root.detailsOpen =
                                !root.detailsOpen
                    }
                }
            }
        }

        // ====================================================
        // DETAILS
        // ====================================================

        Rectangle {
            width: parent.width
            height: detailsOpen ? 62 : 0

            visible: detailsOpen

            color: accent(0.035)

            border.width: 1
            border.color: outline(0.30)

            Row {
                anchors.fill: parent

                anchors.margins: 10

                spacing: 12

                Column {
                    width: (parent.width - 24) / 3

                    spacing: 3

                    Text {
                        text: "IP ADDRESS"

                        color: Theme.Theme.textMuted

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 6
                        font.bold: true
                    }

                    Text {
                        width: parent.width

                        text:
                            root.ipAddress.length
                                ? root.ipAddress
                                : "—"

                        color: Theme.Theme.text

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 8

                        elide:
                            Text.ElideRight
                    }
                }

                Column {
                    width: (parent.width - 24) / 3

                    spacing: 3

                    Text {
                        text: "GATEWAY"

                        color: Theme.Theme.textMuted

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 6
                        font.bold: true
                    }

                    Text {
                        width: parent.width

                        text:
                            root.gateway.length
                                ? root.gateway
                                : "—"

                        color: Theme.Theme.text

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 8

                        elide:
                            Text.ElideRight
                    }
                }

                Column {
                    width: (parent.width - 24) / 3

                    spacing: 3

                    Text {
                        text: "DNS"

                        color: Theme.Theme.textMuted

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 6
                        font.bold: true
                    }

                    Text {
                        width: parent.width

                        text:
                            root.dns.length
                                ? root.dns
                                : "—"

                        color: Theme.Theme.text

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 8

                        elide:
                            Text.ElideRight
                    }
                }
            }
        }

        // ====================================================
        // WI-FI TOOLBAR
        // ====================================================

        Row {
            width: parent.width
            height: 32

            spacing: 7

            Text {
                anchors.verticalCenter:
                    parent.verticalCenter

                text:
                    root.wifiAvailable
                        ? "AVAILABLE WI-FI"
                        : "WI-FI"

                color: Theme.Theme.textMuted

                font.family:
                    "JetBrains Mono Nerd Font"

                font.pixelSize: 8
                font.bold: true

                width: parent.width - 112

                elide:
                    Text.ElideRight
            }

            Item {
                width: 60
                height: 30

                Rectangle {
                    anchors.fill: parent

                    color:
                        root.wifiAvailable &&
                        wifiToggleMouse.containsMouse
                            ? accent(0.12)
                            : "transparent"

                    border.width: 1

                    border.color:
                        !root.wifiAvailable
                            ? outline(0.18)
                            : root.wifiState === "enabled"
                                ? Theme.Theme.accent
                                : outline(0.32)
                }

                Row {
                    anchors.centerIn: parent

                    spacing: 5

                    Text {
                        text:
                            !root.wifiAvailable
                                ? "󰖪"
                                : root.wifiState === "enabled"
                                    ? "󰖩"
                                    : "󰖪"

                        color:
                            !root.wifiAvailable
                                ? Theme.Theme.textMuted
                                : root.wifiState === "enabled"
                                    ? Theme.Theme.accent
                                    : Theme.Theme.textMuted

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 13
                    }

                    Text {
                        text:
                            !root.wifiAvailable
                                ? "N/A"
                                : root.wifiState === "enabled"
                                    ? "ON"
                                    : "OFF"

                        color:
                            !root.wifiAvailable
                                ? Theme.Theme.textMuted
                                : Theme.Theme.text

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 7
                        font.bold: true
                    }
                }

                MouseArea {
                    id: wifiToggleMouse

                    anchors.fill: parent

                    hoverEnabled: true

                    enabled:
                        root.wifiAvailable

                    onClicked:
                        root.toggleWifi()
                }
            }

            Item {
                width: 42
                height: 30

                Rectangle {
                    anchors.fill: parent

                    color:
                        root.wifiAvailable &&
                        scanMouse.containsMouse
                            ? accent(0.12)
                            : "transparent"

                    border.width: 1

                    border.color:
                        root.wifiAvailable
                            ? outline(0.32)
                            : outline(0.18)
                }

                Text {
                    anchors.centerIn: parent

                    text: "󰑐"

                    color:
                        root.wifiAvailable
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 14
                }

                MouseArea {
                    id: scanMouse

                    anchors.fill: parent

                    hoverEnabled: true

                    enabled:
                        root.wifiAvailable

                    onClicked:
                        root.scan()
                }
            }
        }

        // ====================================================
        // PASSWORD
        // ====================================================

        Rectangle {
            width: parent.width
            height: passwordOpen ? 72 : 0

            visible: passwordOpen

            color: accent(0.04)

            border.width: 1
            border.color: Theme.Theme.accent

            Column {
                anchors.fill: parent

                anchors.margins: 8

                spacing: 5

                Text {
                    width: parent.width

                    text:
                        "PASSWORD  •  " +
                        root.selectedSsid

                    color: Theme.Theme.text

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 8
                    font.bold: true

                    elide:
                        Text.ElideRight
                }

                Row {
                    width: parent.width
                    height: 28

                    spacing: 6

                    Rectangle {
                        width: parent.width - 68
                        height: 28

                        color: Theme.Theme.background

                        border.width: 1

                        border.color:
                            passwordInput.activeFocus
                                ? Theme.Theme.accent
                                : outline(0.32)

                        TextInput {
                            id: passwordInput

                            anchors.fill: parent

                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            color: Theme.Theme.text

                            echoMode:
                                TextInput.Password

                            font.family:
                                "JetBrains Mono Nerd Font"

                            font.pixelSize: 8

                            verticalAlignment:
                                TextInput.AlignVCenter

                            onTextChanged:
                                root.password = text
                        }
                    }

                    Item {
                        width: 62
                        height: 28

                        Rectangle {
                            anchors.fill: parent

                            color:
                                connectMouse.containsMouse
                                    ? accent(0.18)
                                    : accent(0.10)

                            border.width: 1
                            border.color:
                                Theme.Theme.accent
                        }

                        Text {
                            anchors.centerIn: parent

                            text: "CONNECT"

                            color: Theme.Theme.accent

                            font.family:
                                "JetBrains Mono Nerd Font"

                            font.pixelSize: 6
                            font.bold: true
                        }

                        MouseArea {
                            id: connectMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked:
                                root.connectPasswordNetwork()
                        }
                    }
                }
            }
        }

        // ====================================================
        // WI-FI LIST
        // ====================================================

        Rectangle {
            width: parent.width

            height:
                root.wifiAvailable &&
                root.wifiNetworks.length > 0
                    ? 126
                    : 38

            color: accent(0.025)

            border.width: 1
            border.color: outline(0.24)

            ListView {
                anchors.fill: parent

                anchors.margins: 4

                visible:
                    root.wifiAvailable &&
                    root.wifiNetworks.length > 0

                clip: true

                model:
                    root.wifiNetworks

                spacing: 2

                delegate: Item {
                    required property var modelData

                    width:
                        ListView.view.width

                    height: 34

                    Rectangle {
                        anchors.fill: parent

                        color:
                            networkMouse.containsMouse
                                ? accent(0.10)
                                : (
                                    modelData.ssid ===
                                    root.currentSsid
                                        ? accent(0.05)
                                        : "transparent"
                                  )

                        border.width:
                            modelData.ssid ===
                            root.currentSsid
                                ? 1
                                : 0

                        border.color:
                            Theme.Theme.accent
                    }

                    Row {
                        anchors.fill: parent

                        anchors.leftMargin: 9
                        anchors.rightMargin: 9

                        spacing: 9

                        Text {
                            anchors.verticalCenter:
                                parent.verticalCenter

                            text:
                                root.signalIcon(
                                    modelData.signal
                                )

                            color:
                                Theme.Theme.accent

                            font.family:
                                "JetBrains Mono Nerd Font"

                            font.pixelSize: 14
                        }

                        Column {
                            anchors.verticalCenter:
                                parent.verticalCenter

                            width:
                                parent.width - 105

                            spacing: 2

                            Text {
                                width: parent.width

                                text:
                                    modelData.ssid

                                color:
                                    Theme.Theme.text

                                font.family:
                                    "JetBrains Mono Nerd Font"

                                font.pixelSize: 8
                                font.bold: true

                                elide:
                                    Text.ElideRight
                            }

                            Text {
                                text:
                                    modelData.security.length &&
                                    modelData.security !== "--"
                                        ? "SECURED"
                                        : "OPEN"

                                color:
                                    Theme.Theme.textMuted

                                font.family:
                                    "JetBrains Mono Nerd Font"

                                font.pixelSize: 6
                            }
                        }

                        Text {
                            anchors.verticalCenter:
                                parent.verticalCenter

                            width: 40

                            text:
                                modelData.signal + "%"

                            horizontalAlignment:
                                Text.AlignRight

                            color:
                                Theme.Theme.accent

                            font.family:
                                "JetBrains Mono Nerd Font"

                            font.pixelSize: 7
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: networkMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        onClicked:
                            root.selectNetwork(
                                modelData
                            )
                    }
                }
            }

            Text {
                anchors.centerIn: parent

                visible:
                    !root.wifiAvailable

                text: "NO WI-FI ADAPTER"

                color:
                    Theme.Theme.textMuted

                font.family:
                    "JetBrains Mono Nerd Font"

                font.pixelSize: 8
                font.bold: true
            }

            Text {
                anchors.centerIn: parent

                visible:
                    root.wifiAvailable &&
                    root.wifiNetworks.length === 0

                text: "NO NETWORKS FOUND"

                color:
                    Theme.Theme.textMuted

                font.family:
                    "JetBrains Mono Nerd Font"

                font.pixelSize: 8
            }
        }

        // ====================================================
        // FOOTER
        // ====================================================

        Text {
            width: parent.width

            text:
                root.statusMessage.length
                    ? root.statusMessage
                    : (
                        root.connectionName.length
                            ? root.connectionName
                            : "NetworkManager"
                      )

            color:
                root.statusMessage.length
                    ? Theme.Theme.accent
                    : Theme.Theme.textMuted

            font.family:
                "JetBrains Mono Nerd Font"

            font.pixelSize: 6

            elide:
                Text.ElideRight
        }
    }
}
