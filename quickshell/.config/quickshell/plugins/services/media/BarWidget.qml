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
  implicitWidth: hasMedia ? row.implicitWidth + Style.space(10) : 0
  implicitHeight: barSize

  // Compact now-playing applet: title + artist only.
  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(5)

    Item {
      id: scrollClip
      width: Math.min(root.maxLabelWidth, labelText.implicitWidth)
      height: labelText.implicitHeight
      clip: true
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.bar.vertical && root.title !== ""

      Text {
        id: labelText
        textFormat: Text.PlainText
        text: root.artist ? root.title + "  ·  " + root.artist : root.title
        color: root.activePlayer && root.activePlayer.isPlaying ? Color.accent : root.bar.barForeground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        font.bold: root.activePlayer && root.activePlayer.isPlaying
        font.weight: Font.Medium
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

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    centerOnBar: true
    contentWidth: popup.fittedContentWidth(Style.space(292))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      // ─────────────────────────────────────────────
      // Now playing — centered composition
      // ─────────────────────────────────────────────
      Column {
        id: hero
        width: parent.width
        spacing: Style.space(8)

        BorderSurface {
          id: artworkFrame
          anchors.horizontalCenter: parent.horizontalCenter
          width: Style.space(88)
          height: Style.space(88)
          radius: Style.spacing.labelGap
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)
          clip: true

          Image {
            anchors.fill: parent
            anchors.margins: Style.space(2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            source: root.activePlayer && root.activePlayer.trackArtUrl
              ? root.activePlayer.trackArtUrl
              : ""
            visible: source !== ""
          }

          Text {
            anchors.centerIn: parent
            visible: !root.activePlayer || !root.activePlayer.trackArtUrl
            text: "󰝚"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
          }
        }

        Column {
          id: metadata
          width: parent.width
          spacing: Style.space(2)

          Text {
            textFormat: Text.PlainText
            text: root.title || "Nothing playing"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 2
            wrapMode: Text.Wrap
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            text: root.artist || "Unknown artist"
            color: root.bar.foreground
            opacity: 0.72
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: text !== ""
          }

          Text {
            textFormat: Text.PlainText
            text: root.album
            color: root.bar.foreground
            opacity: 0.42
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: text !== ""
          }
        }
      }

      PanelSeparator {
        foreground: root.bar.foreground
      }

      // ─────────────────────────────────────────────
      // Playback controls
      // ─────────────────────────────────────────────
      Item {
        width: parent.width
        height: Style.space(58)

        Row {
          id: controlRail
          anchors.centerIn: parent
          width: Style.space(152)
          height: parent.height
          spacing: 0

          Item {
            width: Style.space(44)
            height: parent.height

            Button {
              anchors.centerIn: parent
              iconText: "󰒮"
              foreground: root.bar.foreground
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(8)
              iconSize: Style.font.iconLarge
              enabled: root.activePlayer && root.activePlayer.canGoPrevious
              opacity: enabled ? 1.0 : 0.35
              onClicked: if (root.mediaService)
                root.mediaService.runAction("previous", false, root.mediaService.playerKey(root.activePlayer))
            }
          }

          Item {
            width: Style.space(64)
            height: parent.height

            Button {
              anchors.centerIn: parent
              iconText: root.playIcon
              foreground: root.bar.foreground
              horizontalPadding: Style.space(10)
              verticalPadding: Style.space(8)
              iconSize: Style.font.display
              enabled: root.activePlayer && (root.activePlayer.canTogglePlaying
                || root.activePlayer.canPlay || root.activePlayer.canPause)
              opacity: enabled ? 1.0 : 0.38
              onClicked: if (root.mediaService)
                root.mediaService.runAction("playPause", false, root.mediaService.playerKey(root.activePlayer))
            }
          }

          Item {
            width: Style.space(44)
            height: parent.height

            Button {
              anchors.centerIn: parent
              iconText: "󰒭"
              foreground: root.bar.foreground
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(8)
              iconSize: Style.font.iconLarge
              enabled: root.activePlayer && root.activePlayer.canGoNext
              opacity: enabled ? 1.0 : 0.35
              onClicked: if (root.mediaService)
                root.mediaService.runAction("next", false, root.mediaService.playerKey(root.activePlayer))
            }
          }
        }
      }

      // ─────────────────────────────────────────────
      // Player selector
      // ─────────────────────────────────────────────
      Column {
        id: playersSection
        width: parent.width
        spacing: Style.space(6)
        visible: root.sourcePlayers.length > 1

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(8)

          Text {
            text: "PLAYER"
            color: root.bar.foreground
            opacity: 0.42
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }

          Rectangle {
            width: 1
            height: Style.space(12)
            color: root.bar.foreground
            opacity: 0.14
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: root.identity || "Media"
            color: root.bar.foreground
            opacity: 0.7
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Column {
          id: sourceList
          width: parent.width
          spacing: Style.space(4)

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

              width: sourceList.width
              height: Style.space(46)
              radius: Style.spacing.labelGap
              color: selected
                ? Style.selectedFillFor(root.bar.foreground, Color.accent)
                : Style.normalFillFor(root.bar.foreground, Color.accent)
              opacity: selected ? 1.0 : 0.72
              borderSpec: selected
                ? Border.controlSpec("normal", root.bar.foreground, Color.accent)
                : Border.controlSpec("normal", root.bar.foreground, Color.accent)

              Row {
                anchors.fill: parent
                anchors.leftMargin: sourceRow.borderLeft + Style.space(9)
                anchors.rightMargin: sourceRow.borderRight + Style.space(9)
                spacing: Style.space(8)

                Text {
                  textFormat: Text.PlainText
                  text: sourceRow.player && sourceRow.player.isPlaying ? "󰏤" : "󰐊"
                  color: root.bar.foreground
                  opacity: sourceRow.selected ? 1.0 : 0.55
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                  width: Style.space(18)
                  horizontalAlignment: Text.AlignHCenter
                  anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                  width: parent.width - Style.space(26)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(1)

                  Text {
                    textFormat: Text.PlainText
                    text: sourceRow.sourceTitle
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: sourceRow.selected
                    elide: Text.ElideRight
                    width: parent.width
                  }

                  Text {
                    textFormat: Text.PlainText
                    text: sourceRow.sourceDetail
                    color: root.bar.foreground
                    opacity: 0.45
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
