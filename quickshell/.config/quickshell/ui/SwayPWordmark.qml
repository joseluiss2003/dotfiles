import QtQuick
import QtQuick.Effects
import qs.core

Item {
  id: root

  property color color: Color.brand.accent
  property color highlightColor: Color.brand.highlight
  property color shadowColor: Color.brand.depth

  readonly property real aspectRatio: 540.893 / 157.35065
  readonly property real logoWidth: Math.min(width, height * aspectRatio)
  readonly property real logoHeight: logoWidth / aspectRatio
  readonly property real logoX: (width - logoWidth) / 2
  readonly property real logoY: (height - logoHeight) / 2

  Image {
    id: logoSource
    x: root.logoX
    y: root.logoY
    width: root.logoWidth
    height: root.logoHeight
    source: "assets/swayp-wordmark.svg"
    fillMode: Image.Stretch
    smooth: false
    mipmap: false
    visible: false
  }

  MultiEffect {
    anchors.fill: logoSource
    source: logoSource
    colorizationColor: root.color
    colorization: 1.0
  }
}
