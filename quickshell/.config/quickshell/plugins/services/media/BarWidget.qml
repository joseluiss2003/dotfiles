import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "omarchy.media"

  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("omarchy.media")
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property var sourcePlayers: mediaService ? mediaService.sourcePlayers : []

  readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle || activePlayer.trackArtist)
  readonly property string playIcon: activePlayer && activePlayer.isPlaying ? "󰏤" : "󰐊"
  readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property string album: activePlayer && activePlayer.trackAlbum ? activePlayer.trackAlbum : ""
  readonly property string identity: activePlayer
    ? (activePlayer.identity || activePlayer.desktopEntry || "")
    : ""

  property bool popupOpen: false
  property real maxLabelWidth: 190

  function close() { popupOpen = false }

  visible: hasMedia
  implicitWidth: hasMedia ? row.implicitWidth + Style.space(12) : 0
  implicitHeight: barSize

  // Quiet now-playing strip: accent is reserved for the music glyph.
  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      text: "󰝚"
      color: Color.accent
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
      anchors.verticalCenter: parent.verticalCenter
    }

    Item {
      id: scrollClip
      width: Math.min(root.maxLabelWidth, labelText.implicitWidth)
      height: labelText.implicitHeight
      clip: true
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: labelText
        textFormat: Text.PlainText
        text: root.artist ? root.title + "  ·  " + root.artist : root.title
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
        width: scrollClip.width
        elide: Text.ElideRight
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.activePlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (!root.activePlayer) return
      if (mouse.button === Qt.MiddleButton) {
        if (root.mediaService) root.mediaService.runAction("next", false)
      } else if (mouse.button === Qt.RightButton) {
        if (root.mediaService) root.mediaService.runAction("playPause", false)
      } else if (mouse.button === Qt.LeftButton) {
        root.popupOpen = !root.popupOpen
      }
    }

    onWheel: function(wheel) {
      if (!root.activePlayer) return
      if (wheel.angleDelta.y > 0 && root.mediaService)
        root.mediaService.runAction("previous", false)
      else if (wheel.angleDelta.y < 0 && root.mediaService)
        root.mediaService.runAction("next", false)
    }

    onEntered: if (root.bar)
      root.bar.showTooltip(root, root.hasMedia
        ? (root.title + (root.artist ? " — " + root.artist : ""))
        : "")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  KeyboardPanel {
    id: panel
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    focusTarget: keyCatcher

    padding: 0
    borderSpec: Border.surfaceSpec("media", "panel-wrapper", "transparent", 0)
    contentWidth: Math.min(Style.space(332), panel.availableCardWidth)
    contentHeight: Math.min(
      Style.space(234) + (root.sourcePlayers.length > 1
        ? Style.space(127 + Math.max(0, root.sourcePlayers.length - 2) * 42)
        : 0),
      panel.availableCardHeight
    )
    gap: Style.space(5)

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: root.popupOpen

      Keys.onEscapePressed: function(event) {
        root.close()
        event.accepted = true
      }

      Keys.onSpacePressed: function(event) {
        if (root.mediaService) root.mediaService.runAction("playPause", false, root.mediaService.playerKey(root.activePlayer))
        event.accepted = true
      }

      Keys.onReturnPressed: function(event) {
        if (root.mediaService) root.mediaService.runAction("playPause", false, root.mediaService.playerKey(root.activePlayer))
        event.accepted = true
      }

      Keys.onLeftPressed: function(event) {
        if (root.mediaService) root.mediaService.runAction("previous", false, root.mediaService.playerKey(root.activePlayer))
        event.accepted = true
      }

      Keys.onRightPressed: function(event) {
        if (root.mediaService) root.mediaService.runAction("next", false, root.mediaService.playerKey(root.activePlayer))
        event.accepted = true
      }

      Component.onCompleted: {
        if (root.popupOpen) Qt.callLater(function() { forceActiveFocus() })
      }
    }

    BorderSurface {
      id: card
      anchors.fill: parent
      color: Color.popups.background
      borderSpec: Border.surfaceSpec(
        "media",
        "border",
        Color.popups.border,
        Math.max(1, Style.space(2))
      )
      radius: 0
      clip: true

      Column {
        anchors.fill: parent
        spacing: 0

        // Hero
        Item {
          width: parent.width
          height: Style.space(62)

          Text {
            id: heroIcon
            text: "󰝚"
            color: Color.accent
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.leftMargin: Style.space(14)
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)
            width: parent.width - heroIcon.width - Style.space(42)

            Text {
              text: "Now Playing"
              color: Color.text
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: root.identity ? root.identity.toUpperCase() : "MEDIA"
              color: Color.muted
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.0
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        PanelSeparator {
          width: parent.width - Style.space(20)
          x: Style.space(10)
          foreground: Color.popups.border
        }

        // Track hero: artwork + metadata.
        Item {
          width: parent.width
          height: Style.space(112)

          BorderSurface {
            id: artwork
            width: Style.space(84)
            height: Style.space(84)
            anchors.left: parent.left
            anchors.leftMargin: Style.space(14)
            anchors.verticalCenter: parent.verticalCenter
            color: Util.alpha(Color.text, 0.045)
            borderSpec: Border.controlSpec("normal", Color.text, Color.accent)
            radius: 0
            clip: true

            Image {
              anchors.fill: parent
              anchors.margins: Style.space(2)
              source: root.activePlayer && root.activePlayer.trackArtUrl
                ? root.activePlayer.trackArtUrl
                : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
              visible: source !== ""
            }

            Text {
              anchors.centerIn: parent
              visible: !root.activePlayer || !root.activePlayer.trackArtUrl
              text: "󰝚"
              color: Color.muted
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
            }
          }

          Column {
            anchors.left: artwork.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.rightMargin: Style.space(14)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            Text {
              text: root.title || "Nothing playing"
              color: Color.text
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              width: parent.width
              maximumLineCount: 2
              wrapMode: Text.Wrap
              elide: Text.ElideRight
            }

            Text {
              text: root.artist || "Unknown artist"
              color: Color.text
              opacity: 0.68
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
              width: parent.width
              elide: Text.ElideRight
              visible: text !== ""
            }

            Text {
              text: root.album
              color: Color.muted
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              width: parent.width
              elide: Text.ElideRight
              visible: text !== ""
            }
          }
        }

        PanelSeparator {
          width: parent.width - Style.space(20)
          x: Style.space(10)
          foreground: Color.popups.border
        }

        // Controls: three quiet square controls, with the neutral hover language.
        Item {
          width: parent.width
          height: Style.space(58)

          Row {
            anchors.centerIn: parent
            spacing: Style.space(5)

            MediaControl {
              iconText: "󰒮"
              enabled: !!(root.activePlayer && root.activePlayer.canGoPrevious)
              onClicked: if (root.mediaService)
                root.mediaService.runAction("previous", false, root.mediaService.playerKey(root.activePlayer))
            }

            MediaControl {
              iconText: root.playIcon
              emphasized: true
              enabled: !!(root.activePlayer && (root.activePlayer.canTogglePlaying
                || root.activePlayer.canPlay || root.activePlayer.canPause))
              onClicked: if (root.mediaService)
                root.mediaService.runAction("playPause", false, root.mediaService.playerKey(root.activePlayer))
            }

            MediaControl {
              iconText: "󰒭"
              enabled: !!(root.activePlayer && root.activePlayer.canGoNext)
              onClicked: if (root.mediaService)
                root.mediaService.runAction("next", false, root.mediaService.playerKey(root.activePlayer))
            }
          }
        }

        // Optional player list. Kept compact and inset, like the other redesigned popups.
        Column {
          id: playersSection
          width: parent.width
          spacing: Style.space(4)
          visible: root.sourcePlayers.length > 1

          PanelSeparator {
            width: parent.width - Style.space(20)
            x: Style.space(10)
            foreground: Color.popups.border
          }

          Item {
            width: parent.width
            height: Style.space(30)

            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.space(14)
              anchors.verticalCenter: parent.verticalCenter
              text: "PLAYERS"
              color: Color.muted
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.0
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(4)
            bottomPadding: Style.space(8)

            Repeater {
              model: root.sourcePlayers

              BorderSurface {
                id: sourceRow
                required property var modelData

                readonly property var player: modelData
                readonly property bool selected: root.activePlayer && player
                  && root.mediaService.playerKey(root.activePlayer) === root.mediaService.playerKey(player)
                readonly property string sourceTitle: player
                  ? (player.trackTitle || player.identity || player.desktopEntry || "Media source")
                  : "Media source"
                readonly property string sourceDetail: player && player.trackArtist
                  ? player.trackArtist
                  : (player && player.identity ? player.identity : "")

                width: parent.width - Style.space(20)
                x: Style.space(10)
                height: Style.space(38)
                radius: 0
                color: selected
                  ? Util.alpha(Color.text, 0.075)
                  : Util.alpha(Color.text, 0.025)
                borderSpec: Border.surfaceSpec(
                  "media",
                  selected ? "player-selected" : "player",
                  selected ? Util.alpha(Color.text, 0.16) : Util.alpha(Color.popups.border, 0.18),
                  Math.max(1, Style.space(1))
                )

                Row {
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(9)
                  anchors.rightMargin: Style.space(9)
                  spacing: Style.space(7)

                  Text {
                    text: player && player.isPlaying ? "󰏤" : "󰐊"
                    color: Color.text
                    opacity: selected ? 0.95 : 0.45
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.body
                    width: Style.space(18)
                    horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Style.space(25)
                    spacing: Style.space(1)

                    Text {
                      text: sourceRow.sourceTitle
                      color: Color.text
                      font.family: root.bar.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      font.bold: selected
                      elide: Text.ElideRight
                      width: parent.width
                    }

                    Text {
                      text: sourceRow.sourceDetail
                      color: Color.muted
                      font.family: root.bar.fontFamily
                      font.pixelSize: Style.font.caption
                      elide: Text.ElideRight
                      width: parent.width
                      visible: text !== ""
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor

                  Rectangle {
                    anchors.fill: parent
                    z: -1
                    color: Util.alpha(Color.text, 0.055)
                    visible: parent.containsMouse && !sourceRow.selected
                  }

                  onClicked: if (root.mediaService)
                    root.mediaService.selectPlayer(root.mediaService.playerKey(sourceRow.player))
                }
              }
            }
          }
        }
      }
    }
  }

  component MediaControl: BorderSurface {
    id: control
    signal clicked()
    required property string iconText
    property bool emphasized: false

    width: emphasized ? Style.space(54) : Style.space(44)
    height: Style.space(38)
    radius: 0
    color: controlMouse.containsMouse
      ? Util.alpha(Color.text, 0.075)
      : Util.alpha(Color.text, 0.025)
    borderSpec: Border.surfaceSpec(
      "media-control",
      emphasized ? "primary" : "secondary",
      controlMouse.containsMouse
        ? Util.alpha(Color.text, 0.16)
        : Util.alpha(Color.popups.border, 0.18),
      Math.max(1, Style.space(1))
    )
    opacity: enabled ? 1.0 : 0.35

    Text {
      anchors.centerIn: parent
      text: control.iconText
      color: Color.text
      font.family: root.bar.fontFamily
      font.pixelSize: control.emphasized ? Style.font.display : Style.font.iconLarge
    }

    MouseArea {
      id: controlMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: control.clicked()
    }
  }
}
