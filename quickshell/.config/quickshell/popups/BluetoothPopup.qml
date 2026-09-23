import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

import QtQuick

import "../generated" as Theme

PopupWindow {
    id: root

    property Item anchorItem
    property var adapter: Bluetooth.defaultAdapter

    property bool adapterAvailable: adapter !== null
    property bool scanning: false

    property string statusMessage: ""

    property var discoveredDevices: []
    property var pairedAddresses: []
    property var connectedAddresses: []

    visible: false

    implicitWidth: 370
    implicitHeight: 360

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

    function hasAddress(list, address) {
        for (var i = 0; i < list.length; ++i) {
            if (list[i] === address)
                return true
        }

        return false
    }

    function parseDeviceOutput(text) {
        var result = []
        var lines = text.trim().split("\n")

        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i].trim()

            if (!line.length)
                continue

            var parts = line.split(" ")

            if (parts.length < 3)
                continue

            if (parts[0] !== "Device")
                continue

            var address = parts[1]
            var name = parts.slice(2).join(" ")

            if (!address.length)
                continue

            result.push({
                address: address,
                name: name
            })
        }

        return result
    }

    function parseAddressList(text) {
        var result = []
        var lines = text.trim().split("\n")

        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i].trim()

            if (!line.length)
                continue

            var parts = line.split(" ")

            if (parts.length < 2)
                continue

            if (parts[0] !== "Device")
                continue

            var address = parts[1]

            if (address.length)
                result.push(address)
        }

        return result
    }

    function rebuildDevices() {
        var result = []

        for (var i = 0; i < discoveredDevices.length; ++i) {
            var device = discoveredDevices[i]

            var exists = false

            for (var j = 0; j < result.length; ++j) {
                if (result[j].address === device.address) {
                    exists = true
                    break
                }
            }

            if (exists)
                continue

            result.push({
                address: device.address,
                name: device.name,
                paired: hasAddress(
                    pairedAddresses,
                    device.address
                ),
                connected: hasAddress(
                    connectedAddresses,
                    device.address
                )
            })
        }

        bluetoothModel.clear()

        for (var k = 0; k < result.length; ++k)
            bluetoothModel.append(result[k])
    }

    function refresh() {
        if (!adapterAvailable) {
            bluetoothModel.clear()
            statusMessage = "NO BLUETOOTH ADAPTER"
            return
        }

        deviceProcess.exec({
            command: [
                "bluetoothctl",
                "devices"
            ]
        })

        pairedProcess.exec({
            command: [
                "bluetoothctl",
                "devices",
                "Paired"
            ]
        })

        connectedProcess.exec({
            command: [
                "bluetoothctl",
                "devices",
                "Connected"
            ]
        })
    }

    function toggleAdapter() {
        if (!adapterAvailable)
            return

        adapter.enabled = !adapter.enabled

        statusMessage =
            adapter.enabled
                ? "Bluetooth enabled"
                : "Bluetooth disabled"

        refreshDelay.restart()
    }

    function startScan() {
        if (!adapterAvailable)
            return

        scanning = true
        statusMessage = "Scanning…"

        adapter.enabled = true
        adapter.discovering = true

        scanTimer.restart()
        refreshDelay.restart()
    }

    function stopScan() {
        if (!adapterAvailable)
            return

        adapter.discovering = false
        scanning = false

        refresh()
    }

    function connectDevice(address) {
        statusMessage = "Connecting…"

        connectProcess.exec({
            command: [
                "bluetoothctl",
                "connect",
                address
            ]
        })
    }

    function disconnectDevice(address) {
        statusMessage = "Disconnecting…"

        disconnectProcess.exec({
            command: [
                "bluetoothctl",
                "disconnect",
                address
            ]
        })
    }

    function pairDevice(address) {
        statusMessage = "Pairing…"

        pairProcess.exec({
            command: [
                "sh",
                "-lc",
                "bluetoothctl agent on >/dev/null 2>&1; bluetoothctl default-agent >/dev/null 2>&1; bluetoothctl pair " +
                address
            ]
        })
    }

    Process {
        id: deviceProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.discoveredDevices =
                    root.parseDeviceOutput(text)

                root.rebuildDevices()
            }
        }

        onExited: function(exitCode) {
            if (exitCode !== 0 &&
                root.adapterAvailable) {
                root.statusMessage =
                    "Bluetooth unavailable"
            }
        }
    }

    Process {
        id: pairedProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.pairedAddresses =
                    root.parseAddressList(text)

                root.rebuildDevices()
            }
        }
    }

    Process {
        id: connectedProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.connectedAddresses =
                    root.parseAddressList(text)

                root.rebuildDevices()
            }
        }
    }

    Process {
        id: connectProcess

        onExited: function(exitCode) {
            if (exitCode === 0)
                root.statusMessage = "Connected"
            else
                root.statusMessage = "Connection failed"

            refreshDelay.restart()
        }
    }

    Process {
        id: disconnectProcess

        onExited: function(exitCode) {
            if (exitCode === 0)
                root.statusMessage = "Disconnected"
            else
                root.statusMessage = "Disconnect failed"

            refreshDelay.restart()
        }
    }

    Process {
        id: pairProcess

        onExited: function(exitCode) {
            if (exitCode === 0)
                root.statusMessage = "Paired"
            else
                root.statusMessage = "Pairing failed"

            refreshDelay.restart()
        }
    }

    Timer {
        id: refreshTimer

        interval: 4000
        running: root.visible && root.adapterAvailable
        repeat: true

        onTriggered:
            root.refresh()
    }

    Timer {
        id: refreshDelay

        interval: 1200
        repeat: false

        onTriggered:
            root.refresh()
    }

    Timer {
        id: scanTimer

        interval: 8000
        repeat: false

        onTriggered:
            root.stopScan()
    }

    ListModel {
        id: bluetoothModel
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

                text: root.adapterAvailable
                    ? "󰂯"
                    : "󰂲"

                color: root.adapterAvailable
                    ? Theme.Theme.accent
                    : Theme.Theme.textMuted

                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 20
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                width: parent.width - 90

                spacing: 2

                Text {
                    text: "BLUETOOTH"

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                }

                Text {
                    text: {
                        if (!root.adapterAvailable)
                            return "NO ADAPTER"

                        if (!root.adapter.enabled)
                            return "OFF"

                        if (root.scanning)
                            return "SCANNING"

                        return "ON"
                    }

                    color:
                        root.adapterAvailable &&
                        root.adapter.enabled
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 7
                    font.bold: true
                }
            }

            Item {
                width: 68
                height: 28

                Rectangle {
                    anchors.fill: parent

                    color:
                        root.adapterAvailable &&
                        bluetoothToggleMouse.containsMouse
                            ? accent(0.12)
                            : "transparent"

                    border.width: 1

                    border.color:
                        !root.adapterAvailable
                            ? outline(0.18)
                            : root.adapter.enabled
                                ? Theme.Theme.accent
                                : outline(0.30)
                }

                Row {
                    anchors.centerIn: parent

                    spacing: 5

                    Text {
                        text:
                            !root.adapterAvailable
                                ? "󰂲"
                                : root.adapter.enabled
                                    ? "󰂯"
                                    : "󰂲"

                        color:
                            !root.adapterAvailable
                                ? Theme.Theme.textMuted
                                : root.adapter.enabled
                                    ? Theme.Theme.accent
                                    : Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 12
                    }

                    Text {
                        text:
                            !root.adapterAvailable
                                ? "N/A"
                                : root.adapter.enabled
                                    ? "ON"
                                    : "OFF"

                        color:
                            !root.adapterAvailable
                                ? Theme.Theme.textMuted
                                : Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 7
                        font.bold: true
                    }
                }

                MouseArea {
                    id: bluetoothToggleMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    enabled:
                        root.adapterAvailable

                    onClicked:
                        root.toggleAdapter()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1

            color: outline(0.30)
        }

        // ====================================================
        // ADAPTER
        // ====================================================

        Item {
            width: parent.width
            height: 48

            Rectangle {
                anchors.fill: parent

                color: accent(0.04)

                border.width: 1
                border.color: outline(0.28)
            }

            Row {
                anchors.fill: parent

                anchors.leftMargin: 10
                anchors.rightMargin: 10

                spacing: 9

                Text {
                    anchors.verticalCenter:
                        parent.verticalCenter

                    text: "󰒓"

                    color: root.adapterAvailable
                        ? Theme.Theme.accent
                        : Theme.Theme.textMuted

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 16
                }

                Column {
                    anchors.verticalCenter:
                        parent.verticalCenter

                    width: parent.width - 30

                    spacing: 2

                    Text {
                        text:
                            root.adapterAvailable
                                ? (
                                    root.adapter.name ||
                                    root.adapter.adapterId
                                  )
                                : "No Bluetooth controller"

                        color: Theme.Theme.text

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 8
                        font.bold: true

                        elide:
                            Text.ElideRight
                    }

                    Text {
                        text:
                            root.adapterAvailable
                                ? (
                                    root.adapter.adapterId +
                                    "  •  " +
                                    (
                                        root.adapter.enabled
                                            ? "Powered"
                                            : "Powered off"
                                    )
                                  )
                                : "BlueZ controller not detected"

                        color:
                            root.adapterAvailable &&
                            root.adapter.enabled
                                ? Theme.Theme.accent
                                : Theme.Theme.textMuted

                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize: 6
                    }
                }
            }
        }

        // ====================================================
        // DEVICES / SCAN
        // ====================================================

        Row {
            width: parent.width
            height: 30

            Text {
                anchors.verticalCenter:
                    parent.verticalCenter

                text: "DEVICES"

                color: Theme.Theme.textMuted

                font.family:
                    "JetBrains Mono Nerd Font"

                font.pixelSize: 8
                font.bold: true

                width: parent.width - 48
            }

            Item {
                width: 46
                height: 28

                Rectangle {
                    anchors.fill: parent

                    color:
                        scanMouse.containsMouse
                            ? accent(0.12)
                            : "transparent"

                    border.width: 1
                    border.color:
                        root.adapterAvailable
                            ? Theme.Theme.accent
                            : outline(0.18)
                }

                Text {
                    anchors.centerIn: parent

                    text:
                        root.scanning
                            ? "󰑐"
                            : "󰐂"

                    color:
                        root.adapterAvailable
                            ? Theme.Theme.accent
                            : Theme.Theme.textMuted

                    font.family:
                        "JetBrains Mono Nerd Font"

                    font.pixelSize: 13
                }

                MouseArea {
                    id: scanMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    enabled:
                        root.adapterAvailable

                    onClicked: {
                        if (root.scanning)
                            root.stopScan()
                        else
                            root.startScan()
                    }
                }
            }
        }

        // ====================================================
        // DEVICE LIST
        // ====================================================

        Rectangle {
            width: parent.width
            height: 164

            color: accent(0.025)

            border.width: 1
            border.color: outline(0.24)

            ListView {
                anchors.fill: parent
                anchors.margins: 4

                clip: true

                model: bluetoothModel

                spacing: 2

                delegate: Item {
                    required property string address
                    required property string name
                    required property bool paired
                    required property bool connected

                    width: ListView.view.width
                    height: 38

                    Rectangle {
                        anchors.fill: parent

                        color:
                            deviceMouse.containsMouse
                                ? accent(0.10)
                                : (
                                    connected
                                        ? accent(0.05)
                                        : "transparent"
                                  )

                        border.width:
                            connected ? 1 : 0

                        border.color:
                            Theme.Theme.accent
                    }

                    Row {
                        anchors.fill: parent

                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        spacing: 9

                        Text {
                            anchors.verticalCenter:
                                parent.verticalCenter

                            text:
                                connected
                                    ? "󰂱"
                                    : "󰂯"

                            color:
                                connected
                                    ? Theme.Theme.accent
                                    : Theme.Theme.textMuted

                            font.family:
                                "JetBrains Mono Nerd Font"

                            font.pixelSize: 15
                        }

                        Column {
                            anchors.verticalCenter:
                                parent.verticalCenter

                            width: parent.width - 108

                            spacing: 2

                            Text {
                                width: parent.width

                                text:
                                    name.length
                                        ? name
                                        : "Unknown device"

                                color: Theme.Theme.text

                                font.family:
                                    "JetBrains Mono Nerd Font"

                                font.pixelSize: 8
                                font.bold: true

                                elide:
                                    Text.ElideRight
                            }

                            Text {
                                text:
                                    connected
                                        ? "CONNECTED"
                                        : paired
                                            ? "PAIRED"
                                            : "NOT PAIRED"

                                color:
                                    connected ||
                                    paired
                                        ? Theme.Theme.accent
                                        : Theme.Theme.textMuted

                                font.family:
                                    "JetBrains Mono Nerd Font"

                                font.pixelSize: 6
                                font.bold: true
                            }
                        }

                        Item {
                            width: 68
                            height: 26

                            anchors.verticalCenter:
                                parent.verticalCenter

                            Rectangle {
                                anchors.fill: parent

                                color:
                                    deviceMouse.containsMouse
                                        ? accent(0.12)
                                        : "transparent"

                                border.width: 1

                                border.color:
                                    connected
                                        ? Theme.Theme.accent
                                        : outline(0.30)
                            }

                            Text {
                                anchors.centerIn: parent

                                text:
                                    connected
                                        ? "DISCONNECT"
                                        : paired
                                            ? "CONNECT"
                                            : "PAIR"

                                color:
                                    Theme.Theme.text

                                font.family:
                                    "JetBrains Mono Nerd Font"

                                font.pixelSize: 5
                                font.bold: true
                            }
                        }
                    }

                    MouseArea {
                        id: deviceMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            if (connected) {
                                root.disconnectDevice(address)
                            } else if (paired) {
                                root.connectDevice(address)
                            } else {
                                root.pairDevice(address)
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent

                visible:
                    !root.adapterAvailable

                text: "NO BLUETOOTH ADAPTER"

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
                    root.adapterAvailable &&
                    !root.adapter.enabled

                text: "BLUETOOTH IS OFF"

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
                    root.adapterAvailable &&
                    root.adapter.enabled &&
                    bluetoothModel.count === 0

                text:
                    "NO DEVICES FOUND"

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
                        root.adapterAvailable
                            ? "BlueZ"
                            : "Bluetooth unavailable"
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
