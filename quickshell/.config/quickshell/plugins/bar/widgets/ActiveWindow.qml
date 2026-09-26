import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.active-window"

  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property string title: toplevel ? (toplevel.title || toplevel.appId || "") : ""
  readonly property int maxLabelWidth: Number(setting("maxWidth", 280))

  visible: title !== "" && !vertical
  implicitWidth: visible ? Math.min(maxLabelWidth, titleText.implicitWidth + Style.space(16)) : 0
  implicitHeight: barSize

  Behavior on implicitWidth {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }

  Row {
    anchors.fill: parent
    anchors.leftMargin: Style.space(8)
    anchors.rightMargin: Style.space(8)
    spacing: Style.space(7)

    Text {
      id: focusMark
      anchors.verticalCenter: parent.verticalCenter
      text: "•"
      color: Color.accent
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }

    Text {
      id: titleText
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, parent.width - focusMark.width - parent.spacing)
      text: root.title
      color: Color.accent
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      font.weight: Font.Bold
      elide: Text.ElideRight
      opacity: 1
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: function(mouse) {
      if (!root.toplevel) return
      if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton)
        root.toplevel.close()
      else
        root.toplevel.activate()
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.title)
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}
