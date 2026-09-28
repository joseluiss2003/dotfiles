import QtQuick
import QtQuick.Effects
import qs.core

Item {
  id: root

  property color color: Color.foreground

  Image {
    id: source
    anchors.fill: parent
    source: "assets/power-session.svg"
    fillMode: Image.PreserveAspectFit
    smooth: false
    mipmap: false
    visible: false
  }

  MultiEffect {
    anchors.fill: source
    source: source
    colorizationColor: root.color
    colorization: 1.0
  }
}
