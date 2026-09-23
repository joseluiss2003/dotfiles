import Quickshell
import QtQuick
import QtQuick.Layouts
import "../generated" as Theme


PopupWindow {

    id: root

    required property var anchorItem


    anchor.item: anchorItem
    anchor.margins.bottom: 8


    width: 360
    height: 390


    visible: false
    grabFocus: true
    color: "transparent"


    property date currentDate: new Date()

    property int viewMonth:
        currentDate.getMonth()

    property int viewYear:
        currentDate.getFullYear()



    function daysInMonth() {

        return new Date(
            viewYear,
            viewMonth + 1,
            0
        ).getDate()

    }



    function firstDay() {

        var d = new Date(
            viewYear,
            viewMonth,
            1
        )

        return (d.getDay() + 6) % 7

    }



    function monthText() {

        return Qt.formatDate(
            new Date(
                viewYear,
                viewMonth,
                1
            ),
            "MMMM yyyy"
        )

    }




    Rectangle {

        anchors.fill: parent


        color: Qt.rgba(
            Theme.Theme.background.r,
            Theme.Theme.background.g,
            Theme.Theme.background.b,
            0.97
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

            spacing: 10




            // HEADER


            Rectangle {


                Layout.fillWidth: true

                height: 60



                color: Qt.rgba(
                    Theme.Theme.accent.r,
                    Theme.Theme.accent.g,
                    Theme.Theme.accent.b,
                    0.12
                )



                border.width:1


                border.color: Qt.rgba(
                    Theme.Theme.accent.r,
                    Theme.Theme.accent.g,
                    Theme.Theme.accent.b,
                    0.3
                )



                Row {


                    anchors.fill: parent

                    anchors.leftMargin: 14


                    spacing: 12



                    Text {


                        anchors.verticalCenter: parent.verticalCenter


                        text:"󰃭"


                        color:
                            Theme.Theme.accent


                        font.family:
                            "JetBrains Mono Nerd Font"


                        font.pixelSize:24

                    }



                    Column {


                        anchors.verticalCenter: parent.verticalCenter


                        spacing:2



                        Text {


                            text:
                                Qt.formatDate(
                                    root.currentDate,
                                    "dddd"
                                )


                            color:
                                Theme.Theme.text


                            font.family:
                                "JetBrains Mono Nerd Font"


                            font.pixelSize:14


                            font.bold:true

                        }



                        Text {


                            text:
                                Qt.formatDate(
                                    root.currentDate,
                                    "dd MMMM yyyy"
                                )


                            color:
                                Theme.Theme.textMuted


                            font.family:
                                "JetBrains Mono Nerd Font"


                            font.pixelSize:10

                        }

                    }

                }

            }





            // MONTH CONTROL


            RowLayout {


                Layout.fillWidth:true


                spacing:8




                Rectangle {


                    Layout.preferredWidth:35

                    Layout.preferredHeight:30


                    radius:6



                    color:
                        leftMouse.containsMouse

                        ? Qt.rgba(
                            Theme.Theme.accent.r,
                            Theme.Theme.accent.g,
                            Theme.Theme.accent.b,
                            0.18
                        )

                        :"transparent"



                    Text {

                        anchors.centerIn:parent


                        text:"󰁍"


                        color:
                            Theme.Theme.text


                        font.family:
                            "JetBrains Mono Nerd Font"


                        font.pixelSize:16

                    }



                    MouseArea {


                        id:leftMouse


                        anchors.fill:parent


                        hoverEnabled:true



                        onClicked:{


                            if(root.viewMonth === 0){

                                root.viewMonth = 11
                                root.viewYear--

                            }else{

                                root.viewMonth--

                            }

                        }

                    }

                }





                Text {


                    Layout.fillWidth:true


                    horizontalAlignment:
                        Text.AlignHCenter


                    text:
                        root.monthText()



                    color:
                        Theme.Theme.text



                    font.family:
                        "JetBrains Mono Nerd Font"


                    font.pixelSize:13


                    font.bold:true

                }





                Rectangle {


                    Layout.preferredWidth:35

                    Layout.preferredHeight:30


                    radius:6



                    color:
                        rightMouse.containsMouse

                        ? Qt.rgba(
                            Theme.Theme.accent.r,
                            Theme.Theme.accent.g,
                            Theme.Theme.accent.b,
                            0.18
                        )

                        :"transparent"



                    Text {


                        anchors.centerIn:parent


                        text:"󰁔"


                        color:
                            Theme.Theme.text


                        font.family:
                            "JetBrains Mono Nerd Font"


                        font.pixelSize:16

                    }



                    MouseArea {


                        id:rightMouse


                        anchors.fill:parent


                        hoverEnabled:true



                        onClicked:{


                            if(root.viewMonth === 11){

                                root.viewMonth = 0
                                root.viewYear++

                            }else{

                                root.viewMonth++

                            }

                        }

                    }

                }

            }






            // WEEK DAYS


            Grid {


                Layout.fillWidth:true


                columns:7


                spacing:4



                Repeater {


                    model:[
                        "L",
                        "M",
                        "X",
                        "J",
                        "V",
                        "S",
                        "D"
                    ]



                    Text {


                        width:44

                        height:22


                        horizontalAlignment:
                            Text.AlignHCenter


                        text:modelData


                        color:
                            Theme.Theme.textMuted


                        font.family:
                            "JetBrains Mono Nerd Font"


                        font.pixelSize:10

                    }

                }

            }







            // DAYS


            Grid {


                Layout.fillWidth:true


                columns:7


                spacing:4




                Repeater {


                    model:
                        root.firstDay()
                        +
                        root.daysInMonth()



                    delegate: Rectangle {


                        width:44

                        height:38


                        radius:8



                        property int dayNumber:
                            index -
                            root.firstDay()
                            +
                            1



                        property bool valid:
                            dayNumber > 0 &&
                            dayNumber <= root.daysInMonth()



                        color:


                            valid &&
                            dayNumber === root.currentDate.getDate() &&
                            root.viewMonth === root.currentDate.getMonth() &&
                            root.viewYear === root.currentDate.getFullYear()


                            ?

                            Qt.rgba(
                                Theme.Theme.accent.r,
                                Theme.Theme.accent.g,
                                Theme.Theme.accent.b,
                                0.35
                            )


                            :

                            "transparent"




                        Text {


                            anchors.centerIn:parent


                            visible:
                                parent.valid


                            text:
                                parent.dayNumber


                            color:
                                parent.color === "transparent"

                                ? Theme.Theme.text

                                : Theme.Theme.accent



                            font.family:
                                "JetBrains Mono Nerd Font"


                            font.pixelSize:12


                            font.bold:
                                parent.color !== "transparent"

                        }

                    }

                }

            }

        }

    }

}
