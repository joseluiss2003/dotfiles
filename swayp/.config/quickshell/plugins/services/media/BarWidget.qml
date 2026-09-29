import QtQuick
import Quickshell
import qs.ui
import qs.core

BarWidget {
  id: root
  moduleName: "swayp.media"

  readonly property var mediaService: bar?.shell?.firstPartyServiceFor("swayp.media")
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
  readonly property real openPanelIndicatorWidth: Style.bar.iconSlot

  function close() { popupOpen = false }

  // Media behaves like the other right-side applets: it only occupies space
  // while a player exposes useful track metadata.
  visible: hasMedia
  implicitWidth: hasMedia ? Style.bar.iconSlot : 0
  implicitHeight: barSize

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    foreground: Color.foreground
    passiveColor: Color.foreground
    activeColor: Color.foreground
    hoverColor: Color.foreground
    useActiveColor: false
    text: "󰝚"
    labelVisible: true
    fontSize: Style.font.icon
    horizontalMargin: 0
    verticalPadding: 0
    tooltipText: root.hasMedia
      ? (root.title + (root.artist ? " — " + root.artist : ""))
      : "Media"

    onPressed: function(b) {
      if (!root.activePlayer || !root.mediaService) return
      if (b === Qt.MiddleButton)
        root.mediaService.runAction("next", false)
      else if (b === Qt.RightButton)
        root.mediaService.runAction("playPause", false)
      else
        root.popupOpen = !root.popupOpen
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
      if (!root.activePlayer || !root.mediaService) return
      var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
      root.mediaService.adjustPlayerVolume(delta, root.mediaService.playerKey(root.activePlayer))
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
    gap: Style.popup.gap
    // The media popup owns its card surface below; avoid drawing the
    // KeyboardPanel wrapper a second time over the same translucent card.
    drawBackground: false

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
        Math.max(1, Style.spacing.compactGap)
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
            color: Color.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.leftMargin: Style.spacing.xxxl
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.spacing.sectionGap
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.compactGap
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
              color: Color.textMuted
              opacity: Style.opacity.mutedText
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
          width: parent.width - Style.spacing.wideGap
          x: Style.spacing.sectionGap
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
            anchors.leftMargin: Style.spacing.xxxl
            anchors.verticalCenter: parent.verticalCenter
            color: Color.controls.background
            borderSpec: Border.controlSpec("normal", Color.controls.border, Color.controls.text)
            radius: 0
            clip: true

            Image {
              anchors.fill: parent
              anchors.margins: Style.spacing.compactGap
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
              color: Color.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
            }
          }

          Column {
            anchors.left: artwork.right
            anchors.leftMargin: Style.spacing.xxxl
            anchors.right: parent.right
            anchors.rightMargin: Style.spacing.xxxl
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.sm

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
              opacity: Style.opacity.secondaryText
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
              width: parent.width
              elide: Text.ElideRight
              visible: text !== ""
            }

            Text {
              text: root.album
              color: Color.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              width: parent.width
              elide: Text.ElideRight
              visible: text !== ""
            }
          }
        }

        PanelSeparator {
          width: parent.width - Style.spacing.wideGap
          x: Style.spacing.sectionGap
          foreground: Color.popups.border
        }

        // Controls: three quiet square controls, with the neutral hover language.
        Item {
          width: parent.width
          height: Style.space(58)

          Row {
            anchors.centerIn: parent
            spacing: Style.popup.gap

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
          spacing: Style.spacing.sm
          visible: root.sourcePlayers.length > 1

          PanelSeparator {
            width: parent.width - Style.spacing.wideGap
            x: Style.spacing.sectionGap
            foreground: Color.popups.border
          }

          Item {
            width: parent.width
            height: Style.space(30)

            Text {
              anchors.left: parent.left
              anchors.leftMargin: Style.spacing.xxxl
              anchors.verticalCenter: parent.verticalCenter
              text: "PLAYERS"
              color: Color.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.0
            }
          }

          Column {
            width: parent.width
            spacing: Style.spacing.sm
            bottomPadding: Style.spacing.controlGap

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

                width: parent.width - Style.spacing.wideGap
                x: Style.spacing.sectionGap
                height: Style.space(38)
                radius: 0
                color: selected ? Color.controls.activeBackground : Color.controls.background
                borderSpec: Border.flat(
                  selected ? Color.controls.selectedBorder : Color.controls.border,
                  Math.max(1, Style.spacing.compactGap)
                )

                Row {
                  anchors.fill: parent
                  anchors.leftMargin: Style.spacing.sm
                  anchors.rightMargin: Style.spacing.sm
                  spacing: Style.spacing.sm

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
                    spacing: Style.spacing.compactGap

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
                      color: Color.foreground
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
                    color: Color.controls.hoverBackground
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
      ? Color.controls.hoverBackground
      : Color.controls.background
    borderSpec: Border.flat(
      controlMouse.containsMouse ? Color.controls.selectedBorder : Color.controls.border,
      Math.max(1, Style.spacing.compactGap)
    )
    opacity: enabled ? 1.0 : 0.35

    Text {
      anchors.centerIn: parent
      text: control.iconText
      color: Color.controls.text
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
