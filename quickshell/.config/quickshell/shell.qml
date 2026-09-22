import Quickshell
import QtQuick

import "./components" as Components

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Components.Bar {
                required property var modelData

                barScreen: modelData
            }
        }
    }
}
