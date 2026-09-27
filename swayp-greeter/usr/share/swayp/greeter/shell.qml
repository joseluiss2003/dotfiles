import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property var users: []
    property string username: ""
    property string password: ""
    property string authMessage: ""
    property string errorMessage: ""
    property string authType: ""
    property bool authenticating: false
    property bool startingSession: false
    property date currentTime: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.currentTime = new Date()
    }

    Process {
        id: bridge
        command: ["/usr/bin/python3", "/usr/share/swayp/greeter/greetd-bridge.py"]
        running: true

        stdout: SplitParser {
            onRead: function(line) {
                var response
                try {
                    response = JSON.parse(line)
                } catch (e) {
                    return
                }

                if (response.type === "users") {
                    root.users = response.users || []
                    if (root.username.length === 0 && root.users.length > 0)
                        root.username = root.users[0].name
                    return
                }

                if (response.type === "auth_message") {
                    root.authType = response.auth_message_type || ""
                    root.authMessage = response.auth_message || ""
                    root.authenticating = true
                    root.errorMessage = ""

                    if (root.authType === "info")
                        root.sendAuthResponse("")

                    return
                }

                if (response.type === "success") {
                    if (root.authenticating) {
                        root.authenticating = false
                        root.startingSession = true
                        root.sendStartSession()
                    }
                    return
                }

                if (response.type === "error") {
                    root.errorMessage = response.description || "Authentication failed"
                    root.password = ""
                    root.passwordInput.text = ""
                    root.authenticating = false
                    root.startingSession = false
                    root.passwordInput.forceActiveFocus()
                    return
                }

                if (response.type === "bridge_error")
                    root.errorMessage = response.message || "Greeter bridge error"
            }
        }
    }

    function send(action) {
        bridge.write(JSON.stringify(action) + "\n")
    }

    function beginLogin() {
        if (username.length === 0)
            return

        root.password = ""
        root.errorMessage = ""
        root.authMessage = ""
        root.authType = ""
        root.authenticating = true

        send({
            action: "create_session",
            username: username
        })
    }

    function sendAuthResponse(value) {
        send({
            action: "auth_response",
            response: value
        })
    }

    function sendStartSession() {
        send({
            action: "start_session",
            command: ["/usr/bin/sway"],
            environment: []
        })
    }

    PanelWindow {
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
        color: "#101010"

        Column {
            anchors.centerIn: parent
            spacing: 34

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.currentTime, "HH:mm")
                color: "#f2f2e8"
                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 72
                font.weight: Font.Black
                font.letterSpacing: 5
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.username
                color: "#f2f2e8"
                font.family: "JetBrains Mono Nerd Font"
                font.pixelSize: 18
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Text {
                    width: 48
                    height: 68
                    text: "󰌾"
                    color: "#f2f2e8"
                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 30
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    width: 360
                    height: 68
                    color: "#181818"
                    border.color: root.errorMessage.length > 0 ? "#ff6b6b" : "#f2f2e8"
                    border.width: 2

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.margins: 18
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        color: "#f2f2e8"
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 24
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true
                        enabled: !root.startingSession

                        onAccepted: {
                            if (!root.authenticating)
                                return

                            root.password = text
                            text = ""
                            root.sendAuthResponse(root.password)
                        }
                    }

                    Text {
                        anchors.fill: parent
                        visible: passwordInput.text.length === 0
                        text: root.errorMessage.length > 0
                            ? root.errorMessage
                            : (root.authMessage.length > 0 ? root.authMessage : "Password")
                        color: root.errorMessage.length > 0 ? "#ff6b6b" : "#8f8f8f"
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
            }
        }
    }

    Component.onCompleted:
        root.passwordInput.forceActiveFocus()
}
