import QtQuick
import qs.core

// Compact CLI-style header shared by SwayP popup surfaces.
// Grammar: "> TITLE" on the left, semantic status on the right.
// Optional trailing controls stay interactive without changing the header rhythm.
Item {
  id: root

  property string title: ""
  property string status: ""
  property string iconText: Style.tui.headerMarker
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property real titleVerticalOffset: 0
  property Component trailingControl: null
  property alias statusOpacity: statusText.opacity

  width: parent ? parent.width : implicitWidth
  implicitHeight: Math.max(
    titleText.implicitHeight,
    statusText.implicitHeight,
    trailingLoader.implicitHeight,
    Style.font.body + Style.spacing.sm * 2
  )

  Text {
    id: marker
    textFormat: Text.PlainText
    text: root.iconText
    color: root.accent
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.bold: true
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: root.titleVerticalOffset
  }

  Text {
    id: titleText
    textFormat: Text.PlainText
    text: String(root.title || "").toUpperCase()
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.bold: true
    elide: Text.ElideRight
    anchors.left: marker.right
    anchors.leftMargin: Style.spacing.sm
    anchors.right: statusText.left
    anchors.rightMargin: Style.spacing.md
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: root.titleVerticalOffset
  }

  Text {
    id: statusText
    textFormat: Text.PlainText
    text: String(root.status || "").toUpperCase()
    visible: root.status !== ""
    color: root.foreground
    opacity: 0.82
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
    elide: Text.ElideRight
    anchors.right: trailingLoader.left
    anchors.rightMargin: trailingLoader.visible ? Style.spacing.md : 0
    anchors.verticalCenter: parent.verticalCenter
  }

  Loader {
    id: trailingLoader
    visible: root.trailingControl !== null
    sourceComponent: root.trailingControl
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
  }
}
