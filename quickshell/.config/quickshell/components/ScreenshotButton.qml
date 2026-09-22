import QtQuick
import "../generated" as Theme

Rectangle {
    id: root

    signal clicked()

    width: 30
    height: 28

    color: mouse.containsMouse
        ? Qt.rgba(
            Theme.Theme.text.r,
            Theme.Theme.text.g,
            Theme.Theme.text.b,
            0.08
        )
        : "transparent"

    Text {
        anchors.centerIn: parent

        text: "󰹑"

        color: Theme.Theme.accent

        font.family: "JetBrains Mono Nerd Font"
        font.pixelSize: 17
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            root.clicked()
        }
    }
}
