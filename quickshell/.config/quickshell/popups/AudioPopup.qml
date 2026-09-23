import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "../generated" as Theme


PopupWindow {

    id: root

    required property var anchorItem
    required property var sink

    anchor.item: anchorItem
    anchor.margins.bottom: 6

    width: 340
    height: 250

    visible: false
    grabFocus: true

    color: "transparent"


    function volumePercent() {

        if (!root.sink ||
            !root.sink.ready ||
            !root.sink.audio)
            return 0

        return Math.round(
            root.sink.audio.volume * 100
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

                height: 42


                color: Qt.rgba(
                    Theme.Theme.accent.r,
                    Theme.Theme.accent.g,
                    Theme.Theme.accent.b,
                    0.10
                )


                border.width:1


                border.color: Qt.rgba(
                    Theme.Theme.accent.r,
                    Theme.Theme.accent.g,
                    Theme.Theme.accent.b,
                    0.25
                )



                Row {

                    anchors.fill: parent

                    anchors.leftMargin:12


                    spacing:10



                    Text {

                        anchors.verticalCenter: parent.verticalCenter


                        text:
                            root.sink &&
                            root.sink.audio &&
                            root.sink.audio.muted

                            ? "󰖁"

                            : "󰕾"


                        color:
                            Theme.Theme.accent


                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize:20

                    }



                    Text {


                        anchors.verticalCenter: parent.verticalCenter


                        text:"AUDIO"


                        color:
                            Theme.Theme.text


                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize:11

                        font.bold:true

                    }

                }

            }



            // VOLUME

            Rectangle {


                Layout.fillWidth:true

                height:80



                color: Qt.rgba(
                    Theme.Theme.background.r,
                    Theme.Theme.background.g,
                    Theme.Theme.background.b,
                    0.55
                )



                border.width:1


                border.color: Qt.rgba(
                    Theme.Theme.outline.r,
                    Theme.Theme.outline.g,
                    Theme.Theme.outline.b,
                    0.25
                )



                Column {


                    anchors.centerIn:parent


                    spacing:8



                    Text {


                        anchors.horizontalCenter: parent.horizontalCenter


                        text:
                            root.volumePercent()+"%"


                        color:
                            Theme.Theme.text


                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize:28

                        font.bold:true

                    }



                    Text {


                        anchors.horizontalCenter: parent.horizontalCenter


                        text:
                            root.sink &&
                            root.sink.audio &&
                            root.sink.audio.muted

                            ? "Muted"

                            : "Volume"


                        color:
                            Theme.Theme.textMuted


                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize:10

                    }


                }

            }





            // SLIDER


            Rectangle {

                Layout.fillWidth:true

                height:8


                radius:4


                color: Qt.rgba(
                    Theme.Theme.outline.r,
                    Theme.Theme.outline.g,
                    Theme.Theme.outline.b,
                    0.35
                )



                Rectangle {

                    width:
                        root.sink &&
                        root.sink.audio

                        ? parent.width *
                          root.sink.audio.volume

                        : 0


                    height:parent.height


                    radius:4


                    color:
                        Theme.Theme.accent

                }



                MouseArea {


                    anchors.fill:parent


                    onClicked:function(mouse){


                        if (!root.sink ||
                            !root.sink.audio)
                            return



                        root.sink.audio.volume =
                            Math.max(
                                0,
                                Math.min(
                                    1,
                                    mouse.x /
                                    width
                                )
                            )

                    }

                }

            }




            // BUTTONS


            RowLayout {


                Layout.fillWidth:true


                spacing:8



                Rectangle {


                    Layout.fillWidth:true

                    height:38



                    color:
                        muteMouse.containsMouse

                        ? Qt.rgba(
                            Theme.Theme.accent.r,
                            Theme.Theme.accent.g,
                            Theme.Theme.accent.b,
                            0.16
                        )

                        :"transparent"



                    Text {

                        anchors.centerIn:parent


                        text:
                            root.sink &&
                            root.sink.audio &&
                            root.sink.audio.muted

                            ? "󰝟 Unmute"

                            :"󰕾 Mute"


                        color:
                            Theme.Theme.text


                        font.family:
                            "JetBrains Mono Nerd Font"

                        font.pixelSize:10

                    }



                    MouseArea {


                        id:muteMouse


                        anchors.fill:parent


                        hoverEnabled:true



                        onClicked:{


                            if(root.sink &&
                               root.sink.audio)

                                root.sink.audio.muted =
                                    !root.sink.audio.muted

                        }

                    }

                }


            }



            // DEVICE


            Text {


                Layout.fillWidth:true


                text:
                    root.sink

                    ? root.sink.description

                    :"No audio device"


                color:
                    Theme.Theme.textMuted


                horizontalAlignment:
                    Text.AlignHCenter


                font.family:
                    "JetBrains Mono Nerd Font"


                font.pixelSize:9


                elide:
                    Text.ElideRight

            }

        }

    }

}
