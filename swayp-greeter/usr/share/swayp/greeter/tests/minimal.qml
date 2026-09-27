import QtQuick
import Quickshell

ShellRoot {
    Component.onCompleted: {
        console.log("================================")
        console.log(" SWAYP QUICKSHELL TEST: OK")
        console.log("================================")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            console.log("SwayP QS alive")
        }
    }
}
