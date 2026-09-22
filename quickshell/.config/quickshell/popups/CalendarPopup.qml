import Quickshell
import QtQuick

import "../generated" as Theme

PopupWindow {
    id: root

    required property var anchorItem

    property date monthDate: new Date()

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 300
    height: 285

    visible: false
    color: "transparent"
    grabFocus: true

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    function firstDay(year, month) {
        var d = new Date(year, month, 1).getDay()
        return d === 0 ? 6 : d - 1
    }

    Rectangle {
        anchors.fill: parent

        color: Theme.Theme.surface
        border.width: 1
        border.color: Theme.Theme.outline
        radius: 0

        Column {
            anchors.fill: parent
            anchors.margins: 16

            spacing: 12

            Row {
                width: parent.width

                Text {
                    width: parent.width - 70

                    text: Qt.formatDate(
                        root.monthDate,
                        "MMMM yyyy"
                    )

                    color: Theme.Theme.text

                    font.family: "JetBrains Mono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                }

                Rectangle {
                    width: 30
                    height: 28

                    color: previousMonthMouse.containsMouse
                        ? Theme.Theme.accentSoft
                        : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "󰁍"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: previousMonthMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            root.monthDate = new Date(
                                root.monthDate.getFullYear(),
                                root.monthDate.getMonth() - 1,
                                1
                            )
                        }
                    }
                }

                Rectangle {
                    width: 30
                    height: 28

                    color: nextMonthMouse.containsMouse
                        ? Theme.Theme.accentSoft
                        : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: "󰁔"

                        color: Theme.Theme.text

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: nextMonthMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            root.monthDate = new Date(
                                root.monthDate.getFullYear(),
                                root.monthDate.getMonth() + 1,
                                1
                            )
                        }
                    }
                }
            }

            Grid {
                columns: 7
                spacing: 0

                Repeater {
                    model: [
                        "L", "M", "X", "J",
                        "V", "S", "D"
                    ]

                    delegate: Text {
                        width: 38
                        height: 24

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter

                        text: modelData

                        color: Theme.Theme.textMuted

                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }

            Grid {
                columns: 7
                rows: 6
                spacing: 0

                Repeater {
                    model: 42

                    delegate: Rectangle {
                        width: 38
                        height: 30

                        property int indexInMonth:
                            index -
                            root.firstDay(
                                root.monthDate.getFullYear(),
                                root.monthDate.getMonth()
                            ) + 1

                        property bool validDay:
                            indexInMonth >= 1 &&
                            indexInMonth <= root.daysInMonth(
                                root.monthDate.getFullYear(),
                                root.monthDate.getMonth()
                            )

                        property bool today:
                            validDay &&
                            indexInMonth === new Date().getDate() &&
                            root.monthDate.getMonth() === new Date().getMonth() &&
                            root.monthDate.getFullYear() === new Date().getFullYear()

                        color: today
                            ? Theme.Theme.accent
                            : "transparent"

                        Text {
                            anchors.centerIn: parent

                            text: parent.validDay
                                ? parent.indexInMonth
                                : ""

                            color: parent.today
                                ? Theme.Theme.accentText
                                : Theme.Theme.text

                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 11
                            font.bold: parent.today
                        }
                    }
                }
            }
        }
    }
}
