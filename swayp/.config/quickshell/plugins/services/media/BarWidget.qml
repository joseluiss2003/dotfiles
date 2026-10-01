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
  readonly property bool hasPlaybackStream: !!(mediaService && activePlayer
    && mediaService.playerHasPlaybackStream(activePlayer))
  readonly property bool hasMedia: activePlayer !== null
    && !!activePlayer.isPlaying
    && (activePlayer.trackTitle || activePlayer.trackArtist)
    && hasPlaybackStream
  readonly property string playIcon: activePlayer && activePlayer.isPlaying ? "󰏤" : "󰐊"
  readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
  readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
  readonly property string album: activePlayer && activePlayer.trackAlbum ? activePlayer.trackAlbum : ""
  readonly property string identity: activePlayer
    ? (activePlayer.identity || activePlayer.desktopEntry || "")
    : ""

  property bool popupOpen: false
  property int selectedPlayerIndex: 0

  visible: hasMedia
  implicitWidth: hasMedia ? Style.bar.iconSlot : 0
  implicitHeight: barSize

  function close() {
    popupOpen = false
  }

  function action(name) {
    if (!mediaService || !activePlayer) return
    mediaService.runAction(name, false, mediaService.playerKey(activePlayer))
  }

  function selectPlayerAt(index) {
    if (!mediaService || index < 0 || index >= sourcePlayers.length) return
    var player = sourcePlayers[index]
    if (!player) return
    selectedPlayerIndex = index
    mediaService.selectPlayer(mediaService.playerKey(player))
  }

  onSourcePlayersChanged: {
    if (sourcePlayers.length === 0) {
      selectedPlayerIndex = 0
      return
    }
    selectedPlayerIndex = Math.max(0, Math.min(selectedPlayerIndex, sourcePlayers.length - 1))
  }

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
    fontSize: Style.bar.iconFont
    horizontalMargin: 0
    verticalPadding: 0
    tooltipText: root.hasMedia
      ? (root.title + (root.artist ? " — " + root.artist : ""))
      : "Media"

    onPressed: function(b) {
      if (!root.activePlayer || !root.mediaService) return
      if (b === Qt.MiddleButton)
        root.action("next")
      else if (b === Qt.RightButton)
        root.action("playPause")
      else
        root.popupOpen = !root.popupOpen
    }

    onWheelMoved: function(delta) {
      if (!root.activePlayer || !root.mediaService) return
      var step = delta > 0 ? 0.05 : -0.05
      root.mediaService.adjustPlayerVolume(
        step,
        root.mediaService.playerKey(root.activePlayer)
      )
    }
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
    contentWidth: Math.min(Style.space(344), panel.availableCardWidth)
    contentHeight: Math.min(panelColumn.implicitHeight, panel.availableCardHeight)
    gap: Style.popup.gap
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
        root.action("playPause")
        event.accepted = true
      }

      Keys.onReturnPressed: function(event) {
        root.action("playPause")
        event.accepted = true
      }

      Keys.onLeftPressed: function(event) {
        root.action("previous")
        event.accepted = true
      }

      Keys.onRightPressed: function(event) {
        root.action("next")
        event.accepted = true
      }

      Keys.onUpPressed: function(event) {
        if (root.sourcePlayers.length > 0)
          root.selectPlayerAt((root.selectedPlayerIndex - 1 + root.sourcePlayers.length)
            % root.sourcePlayers.length)
        event.accepted = true
      }

      Keys.onDownPressed: function(event) {
        if (root.sourcePlayers.length > 0)
          root.selectPlayerAt((root.selectedPlayerIndex + 1) % root.sourcePlayers.length)
        event.accepted = true
      }

      Component.onCompleted: if (root.popupOpen)
        Qt.callLater(function() { forceActiveFocus() })
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
        id: panelColumn
        anchors.fill: parent
        anchors.margins: Style.popup.contentInset
        spacing: Style.spacing.panelGap

        // Media gets a tiny breathing gap above the CLI header without
        // changing the shared popup framing used by the other panels.
        Item {
          width: parent.width
          height: Style.spacing.sm
        }

        PanelCliHeader {
          title: "Media"
          status: root.identity ? root.identity : "NOW PLAYING"
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
        }

        PanelSeparator {
          width: parent.width
          foreground: Color.popups.border
        }

        // Track information stays compact: metadata sits at the top-right
        // of the artwork and playback controls live directly underneath it.
        // This keeps the player row short and lets the players list move up.
        Item {
          width: parent.width
          implicitHeight: artwork.height

          BorderSurface {
            id: artwork
            width: Style.space(112)
            height: Style.space(112)
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: Color.controls.background
            borderSpec: Border.flat(Color.controls.border, Math.max(1, Style.spacing.compactGap))
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
              font.pixelSize: Style.font.iconLarge
            }
          }

          Column {
            id: trackInfo
            anchors.left: artwork.right
            anchors.leftMargin: Style.spacing.panelGap
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: Style.spacing.xs

            Text {
              text: root.title || "NOTHING PLAYING"
              color: Color.text
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              width: parent.width
              maximumLineCount: 1
              elide: Text.ElideRight
            }

            Text {
              text: root.artist || "UNKNOWN ARTIST"
              color: Color.foreground
              opacity: Style.opacity.secondaryText
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              width: parent.width
              elide: Text.ElideRight
            }

            Text {
              text: root.album
              color: Color.foreground
              opacity: Style.opacity.mutedText
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              width: parent.width
              elide: Text.ElideRight
              visible: text !== ""
            }

            // Playback controls sit immediately below the metadata instead
            // of consuming a full-width row underneath the artwork.
            Row {
              width: implicitWidth
              height: Style.space(38)
              spacing: Style.spacing.xxl

              Item {
                width: Style.space(34)
                height: parent.height

                Text {
                  anchors.centerIn: parent
                  text: "󰒮"
                  color: previousMouse.containsMouse ? Color.accent : Color.foreground
                  opacity: root.activePlayer && root.activePlayer.canGoPrevious ? 1.0 : 0.35
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.iconLarge
                }

                MouseArea {
                  id: previousMouse
                  anchors.fill: parent
                  enabled: !!(root.activePlayer && root.activePlayer.canGoPrevious)
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.action("previous")
                }
              }

              Item {
                width: Style.space(40)
                height: parent.height

                Text {
                  anchors.centerIn: parent
                  text: root.playIcon
                  color: playMouse.containsMouse ? Color.accent : Color.foreground
                  opacity: root.activePlayer && (
                    root.activePlayer.canTogglePlaying
                    || root.activePlayer.canPlay
                    || root.activePlayer.canPause
                  ) ? 1.0 : 0.35
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.display
                  font.bold: true
                }

                MouseArea {
                  id: playMouse
                  anchors.fill: parent
                  enabled: !!(root.activePlayer && (
                    root.activePlayer.canTogglePlaying
                    || root.activePlayer.canPlay
                    || root.activePlayer.canPause
                  ))
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.action("playPause")
                }
              }

              Item {
                width: Style.space(38)
                height: parent.height

                Text {
                  anchors.centerIn: parent
                  text: "󰒭"
                  color: nextMouse.containsMouse ? Color.accent : Color.foreground
                  opacity: root.activePlayer && root.activePlayer.canGoNext ? 1.0 : 0.35
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.iconLarge
                }

                MouseArea {
                  id: nextMouse
                  anchors.fill: parent
                  enabled: !!(root.activePlayer && root.activePlayer.canGoNext)
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.action("next")
                }
              }
            }
          }
        }

        // Multiple MPRIS players become a compact TUI list.
        Column {
          id: playersSection
          width: parent.width
          spacing: Style.spacing.sm
          visible: root.sourcePlayers.length > 0

          PanelSeparator {
            width: parent.width
            foreground: Color.popups.border
          }

          PanelSectionHeader {
            text: "PLAYERS"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Repeater {
            model: root.sourcePlayers

            CursorSurface {
              id: sourceRow
              required property var modelData
              required property int index

              readonly property var player: modelData
              readonly property bool selected: root.activePlayer && player
                && root.mediaService.playerKey(root.activePlayer) === root.mediaService.playerKey(player)

              width: parent.width
              implicitHeight: sourceText.implicitHeight + Style.spacing.xs
              hasCursor: root.selectedPlayerIndex === index
              cursorMarkerVerticalOffset: -(sourceText.implicitHeight - playerTitle.implicitHeight) / 2
              foreground: root.bar.foreground
              fill: "transparent"
              currentFill: "transparent"
              showCursorMarker: true

              Column {
                id: sourceText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Style.spacing.xxxl
                anchors.rightMargin: Style.spacing.md
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.spacing.xs

                Text {
                  id: playerTitle
                  text: String(player && (player.trackTitle || player.identity || player.desktopEntry) || "MEDIA")
                    + (player && player.isPlaying ? " · PLAYING" : "")
                  color: selected ? Color.foreground : Color.text
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: selected
                  width: parent.width
                  elide: Text.ElideRight
                }

                Text {
                  text: player && player.trackArtist
                    ? player.trackArtist
                    : String(player && (player.identity || player.desktopEntry) || "")
                  color: Color.foreground
                  opacity: Style.opacity.secondaryText
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  width: parent.width
                  elide: Text.ElideRight
                  visible: text !== ""
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse) root.selectedPlayerIndex = index
                onClicked: root.selectPlayerAt(index)
              }
            }
          }

          Item {
            width: parent.width
            height: Style.spacing.huge
          }
        }
      }
    }
  }}
